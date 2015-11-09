////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMRealm_Private.hpp"

#import "RLMAnalytics.hpp"
#import "RLMArray_Private.hpp"
#import "RLMRealmConfiguration_Private.h"
#import "RLMMigration_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMObjectStore.h"
#import "RLMObject_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealmUtil.hpp"
#import "RLMSchema_Private.hpp"
#import "RLMUpdateChecker.hpp"
#import "RLMUtil.hpp"

#include "object_store.hpp"
#include "schema.hpp"
#include "shared_realm.hpp"

#include <realm/sync/commit_log.hpp>
#include <realm/disable_sync_to_disk.hpp>
#include <realm/lang_bind_helper.hpp>
#include <realm/util/memory_stream.hpp>
#include <realm/version.hpp>

using namespace realm;
using util::File;

// Access to s_syncSessions (referenced NSMapTable object), s_serverConnections
// (referenced NSMapTable object), and s_lastServerConnectionIdent, must be
// synchronized with respect to s_realmsPerPath.

// Maps local path to RLMSyncSession instance
NSMapTable *s_syncSessions = [NSMapTable strongToWeakObjectsMapTable];

// Maps "server:port" to RLMServerConnection instance
NSMapTable *s_serverConnections = [NSMapTable strongToWeakObjectsMapTable];

unsigned long s_lastServerConnectionIdent = 0;

std::atomic<bool> s_syncLogEverything(false);

// Instances of RLMServerConnection and RLMSyncSession may be created by any
// thread, but all instance methods must be called by the main thread, except
// backgroundTask and backgroundApplyChangeset in RLMSyncSession which are
// called internally from a background thread.

@interface RLMOutputMessage : NSObject
@property (nonatomic) NSString *head;
@property (nonatomic) NSData *body; // May be nil
@end

@interface RLMServerConnection : NSObject <NSStreamDelegate>
@property (readonly, nonatomic) unsigned long ident; // Used only for logging
@property (readonly, nonatomic) NSString *identity;
@property (readonly, nonatomic) BOOL isOpen;
@end

@interface RLMSyncSession : NSObject
@property (readonly, nonatomic) RLMServerConnection *connection;
@property (readonly, nonatomic) NSNumber *sessionIdent;
@property (nonatomic) uint_fast64_t serverFileIdent;
@property (nonatomic) uint_fast64_t clientFileIdent;
@property (readonly, nonatomic) NSString *serverPath;
@property (readonly, nonatomic) RLMRealmConfiguration *configuration;

- (void)connectionIsOpen;
- (void)connectionIsOpenAndSessionHasFileIdent;
- (void)connectionIsClosed;
- (void)handleAllocMessageWithServerFileIdent:(uint_fast64_t)serverFileIdent
                              clientFileIdent:(uint_fast64_t)clientFileIdent;
- (void)handleDownloadMessageWithServerVersion:(Replication::version_type)serverVersion
                                 clientVersion:(Replication::version_type)clientVersion
                                     changeset:(NSData *)changeset
                               originTimestamp:(uint_fast64_t)originTimestamp
                               originFileIdent:(uint_fast64_t)originFileIdent
                               moreIsAvailable:(bool)moreIsAvailable;
- (void)handleProgressMessageWithServerVersion:(Replication::version_type)serverVersion
                                 clientVersion:(Replication::version_type)clientVersion;
@end


@implementation RLMOutputMessage {
    void (^_completionHandler)();
}

- (instancetype)init {
    self = [super init];
    if (self)
        _completionHandler = nil;
    return self;
}

- (void (^)())completionHandler {
    return _completionHandler;
}

- (void)setCompletionHandler:(void (^)())block {
    _completionHandler = block;
}

@end


@implementation RLMServerConnection {
    BOOL _isOpen;

    NSString *_address;
    NSNumber *_port;

    NSRunLoop *_runLoop;

    NSInputStream  *_inputStream;
    NSOutputStream *_outputStream;

    BOOL _inputIsHead;
    size_t _inputBufferSize;
    std::unique_ptr<char[]> _inputBuffer;

    size_t _headBufferSize;
    std::unique_ptr<char[]> _headBuffer;
    char *_headBufferCurr;

    size_t _messageBodySize;
    NSMutableData *_messageBodyBuffer;
    char *_messageBodyCurr;
    void (^_messageHandler)();

    NSMutableArray *_outputQueue; // Of RLMOutputMessage instances
    NSData *_currentOutputChunk;
    NSData *_nextOutputChunk;
    void (^_outputCompletionHandler)();
    const char *_currentOutputBegin;
    const char *_currentOutputEnd;

    unsigned _lastSessionIdent;

    // Maps session identifiers to an RLMSyncSession instances. A session
    // identifier is a locally assigned integer that uniquely identifies the
    // RLMSyncSession instance within a particular server connection.
    NSMapTable *_sessions;
}


- (instancetype)initWithIdent:(unsigned long)ident
                     identity:(NSString *)identity
                      address:(NSString *)address
                         port:(NSNumber *)port {
    self = [super init];
    if (self) {
        _ident = ident;
        _identity = [identity copy];
        _isOpen = NO;

        _address = address;
        _port = port ? port : [NSNumber numberWithInt:7800];

        _runLoop = nil;

        _inputBufferSize = 1024;
        _inputBuffer = std::make_unique<char[]>(_inputBufferSize);

        _headBufferSize = 256;
        _headBuffer = std::make_unique<char[]>(_headBufferSize);

        _currentOutputChunk = nil;
        _nextOutputChunk = nil;
        _outputCompletionHandler = nil;

        _lastSessionIdent = 0;
        _sessions = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}


- (unsigned)newSessionIdent
{
    return ++_lastSessionIdent;
}


- (void)mainThreadInit {
    // Called by main thread
    if (_runLoop)
        return;
    _runLoop = [NSRunLoop currentRunLoop];

    [self open];
}


- (void)open {
    if (_isOpen)
        return;

    NSLog(@"RealmSync: Connection[%lu]: Opening connection to %@:%@", _ident, _address, _port);

    CFAllocatorRef defaultAllocator = 0;
    CFStringRef address2 = (__bridge CFStringRef)_address;
    UInt32 port2 = UInt32(_port.unsignedLongValue);
    CFReadStreamRef  readStream  = 0;
    CFWriteStreamRef writeStream = 0;
    CFStreamCreatePairWithSocketToHost(defaultAllocator, address2, port2,
                                       &readStream, &writeStream);
    NSInputStream  *inputStream  = (__bridge_transfer NSInputStream  *)readStream;
    NSOutputStream *outputStream = (__bridge_transfer NSOutputStream *)writeStream;

    [inputStream setDelegate:self];
    [outputStream setDelegate:self];

    [inputStream scheduleInRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];

    _inputStream  = inputStream;
    _outputStream = outputStream;

    _inputIsHead = YES;
    _headBufferCurr = _headBuffer.get();

    _outputQueue = [NSMutableArray array];

    _isOpen = YES;

    [self sendIdentMessage];

    for (NSNumber *sessionIdent in _sessions) {
        RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
        [session connectionIsOpen];
    }
}


- (void)closeAndTryToReconnectLater {
    if (!_isOpen)
        return;

    [_inputStream close];
    [_outputStream close];

    _inputStream  = nil;
    _outputStream = nil;

    _outputQueue = nil;
    _currentOutputChunk = nil;
    _nextOutputChunk = nil;
    _outputCompletionHandler = nil;

    _isOpen = NO;

    for (NSNumber *sessionIdent in _sessions) {
        RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
        [session connectionIsClosed];
    }

    NSTimeInterval reconnectDelay = 5;

    NSLog(@"RealmSync: Connection[%lu]: Closed (will try to reconnect in %g seconds)",
          _ident, double(reconnectDelay));

    [self performSelector:@selector(open) withObject:nil afterDelay:reconnectDelay];
}


- (void)addSession:(RLMSyncSession *)session {
    [_sessions setObject:session forKey:session.sessionIdent];
    if (_isOpen)
        [session connectionIsOpen];
}


- (void)sendIdentMessage {
    // FIXME: These need to be set correctly (tentative:
    // `applicationIdent` is a unique application identifier registered with
    // Realm and `userIdent` could for example be the concattenation of a user
    // name and a password).
    NSData *applicationIdent = [@"dummy_app"  dataUsingEncoding:NSUTF8StringEncoding];
    if (self.identity == nil) {
        NSLog(@"RealmSync: No user identity set (using default, which probably won't work).");
        _identity = @"dummy_user";
    }
    NSData *userIdentData = [self.identity dataUsingEncoding:NSUTF8StringEncoding];

    NSMutableData *body = [applicationIdent mutableCopy];
    [body appendData:userIdentData];

    uint_fast64_t protocolVersion = 1;
    size_t applicationIdentSize = size_t(applicationIdent.length);
    size_t userIdentSize        = size_t(userIdentData.length);
    typedef unsigned long      ulong;
    typedef unsigned long long ulonglong;
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.body = body;
    msg.head = [NSString stringWithFormat:@"ident %llu %lu %lu\n", ulonglong(protocolVersion),
                         ulong(applicationIdentSize), ulong(userIdentSize)];
    [self enqueueOutputMessage:msg];
    NSLog(@"RealmSync: Connection[%lu]: Sending: IDENT", _ident);
}


- (void)sendAllocMessageWithSessionIdent:(NSNumber *)sessionIdent
                              serverPath:(NSString *)serverPath {
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    typedef unsigned long ulong;
    msg.body = [serverPath dataUsingEncoding:NSUTF8StringEncoding];
    msg.head = [NSString stringWithFormat:@"alloc %@ %lu\n", sessionIdent, ulong(msg.body.length)];
    [self enqueueOutputMessage:msg];
    NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Sending: ALLOC(server_path='%@')", _ident,
          sessionIdent, serverPath);
}


- (void)sendBindMessageWithSessionIdent:(NSNumber *)sessionIdent
                        serverFileIdent:(uint_fast64_t)serverFileIdent
                        clientFileIdent:(uint_fast64_t)clientFileIdent
                             serverPath:(NSString *)serverPath
                          serverVersion:(Replication::version_type)serverVersion
                          clientVersion:(Replication::version_type)clientVersion {
    typedef unsigned long      ulong;
    typedef unsigned long long ulonglong;
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.body = [serverPath dataUsingEncoding:NSUTF8StringEncoding];
    msg.head = [NSString stringWithFormat:@"bind %@ %llu %llu %lu %llu %llu\n", sessionIdent,
                         ulonglong(serverFileIdent), ulonglong(clientFileIdent),
                         ulong(msg.body.length), ulonglong(serverVersion),
                         ulonglong(clientVersion)];
    [self enqueueOutputMessage:msg];
    NSLog(@"RealmSync: Connection[%lu]: Sessions[%@]: Sending: BIND(server_file_ident=%llu, "
          "client_file_ident=%llu, server_path='%@', server_version=%llu, client_version=%llu)",
          _ident, sessionIdent, ulonglong(serverFileIdent), ulonglong(clientFileIdent), serverPath,
          ulonglong(serverVersion), ulonglong(clientVersion));
}


- (void)sendUnbindMessageWithSessionIdent:(NSNumber *)sessionIdent {
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.head = [NSString stringWithFormat:@"unbind %@\n", sessionIdent];
    [self enqueueOutputMessage:msg];
    NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Sending: UNBIND", _ident, sessionIdent);
}


- (void)enqueueOutputMessage:(RLMOutputMessage *)msg {
    [_outputQueue addObject:msg];
    if (_isOpen && !_currentOutputChunk) {
        [self resumeOutput];
        [_outputStream scheduleInRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
    }
}


- (BOOL)resumeOutput {
    if (_nextOutputChunk) {
        _currentOutputChunk = _nextOutputChunk;
        _nextOutputChunk = nil;
    }
    else {
        if (_outputCompletionHandler) {
            void (^completionHandler)();
            completionHandler = _outputCompletionHandler;
            _outputCompletionHandler = nil;
            // This handler is allowed to enqueue new output messages
            completionHandler();
        }
        RLMOutputMessage *msg = _outputQueue.firstObject;
        if (!msg)
            return NO;
        _currentOutputChunk = [msg.head dataUsingEncoding:NSUTF8StringEncoding];
        _nextOutputChunk = msg.body;
        if (_nextOutputChunk.length == 0)
            _nextOutputChunk = nil;
        _outputCompletionHandler = msg.completionHandler;
        [_outputQueue removeObjectAtIndex:0];
    }
    _currentOutputBegin = static_cast<const char*>(_currentOutputChunk.bytes);
    _currentOutputEnd   = _currentOutputBegin + _currentOutputChunk.length;
    return YES;
}


- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable: {
            if (stream != _inputStream)
                return;
            uint8_t *buffer = reinterpret_cast<uint8_t *>(_inputBuffer.get());
            NSUInteger length = _inputBufferSize;
            NSInteger n = [_inputStream read:buffer maxLength:length];
            if (n < 0) {
                NSLog(@"RealmSync: Connection[%lu]: Error reading from socket: %@",
                      _ident, _inputStream.streamError);
                [self closeAndTryToReconnectLater];
                return;
            }
            if (n == 0)
                goto end_of_input;
            char *headBufferBegin = _headBuffer.get();
            char *headBufferEnd = headBufferBegin + _headBufferSize;
            const char *inputBegin = _inputBuffer.get();
            const char *inputEnd = inputBegin + n;
            if (!_inputIsHead)
                goto body;
            for (;;) {
                // Message head
                {
                    size_t sourceAvail = inputEnd - inputBegin;
                    size_t destAvail = headBufferEnd - _headBufferCurr;
                    size_t avail = std::min(sourceAvail, destAvail);
                    const char *i = std::find(inputBegin, inputBegin + avail, '\n');
                    _headBufferCurr = std::copy(inputBegin, i, _headBufferCurr);
                    if (_headBufferCurr == headBufferEnd) {
                        NSLog(@"RealmSync: Connection[%lu]: Message head too big", _ident);
                        [self closeAndTryToReconnectLater];
                        return;
                    }
                    inputBegin = i;
                    if (inputBegin == inputEnd)
                        break;
                    ++inputBegin; // Discard newline from input
                    _inputIsHead = NO;

                    util::MemoryInputStream parser;
                    parser.set_buffer(headBufferBegin, _headBufferCurr);
                    _headBufferCurr = headBufferBegin;
                    parser.unsetf(std::ios_base::skipws);

                    std::string message_type;
                    parser >> message_type;

                    _messageHandler = nil;
                    __weak RLMServerConnection *weakSelf = self;
                    if (message_type == "download") {
                        // A new foreign changeset is available for download
                        unsigned sessionIdent = 0;
                        Replication::version_type serverVersion = 0;
                        Replication::version_type clientVersion = 0;
                        size_t changesetSize = 0;
                        uint_fast64_t originTimestamp = 0;
                        uint_fast64_t originFileIdent = 0;
                        bool moreIsAvailable = false;
                        char sp1, sp2, sp3, sp4, sp5, sp6, sp7;
                        parser >> sp1 >> sessionIdent >> sp2 >> serverVersion >> sp3 >>
                            clientVersion >> sp4 >> changesetSize >> sp5 >>
                            originTimestamp >> sp6 >> originFileIdent >> sp7 >> moreIsAvailable;
                        bool good = parser && parser.eof() && sp1 == ' ' && sp2 == ' ' &&
                            sp3 == ' ' && sp4 == ' ' && sp5 == ' ' && sp6 == ' ' && sp7 == ' ';
                        if (!good) {
                            NSLog(@"RealmSync: Connection[%lu]: Bad DOWNLOAD message "
                                  "from server", _ident);
                            [self closeAndTryToReconnectLater];
                            return;
                        }
                        _messageBodySize = changesetSize;
                        _messageHandler = ^{
                            NSNumber *sessionIdent2 = [NSNumber numberWithUnsignedInteger:sessionIdent];
                            [weakSelf handleDownloadMessageWithSessionIdent:sessionIdent2
                                                              serverVersion:serverVersion
                                                              clientVersion:clientVersion
                                                            originTimestamp:originTimestamp
                                                            originFileIdent:originFileIdent
                                                            moreIsAvailable:moreIsAvailable];
                        };
                    }
                    else if (message_type == "progress") {
                        unsigned sessionIdent = 0;
                        Replication::version_type serverVersion = 0;
                        Replication::version_type clientVersion = 0;
                        char sp1, sp2, sp3;
                        parser >> sp1 >> sessionIdent >> sp2 >> serverVersion >> sp3 >>
                            clientVersion;
                        bool good = parser && parser.eof() && sp1 == ' ' && sp2 == ' ' &&
                            sp3 == ' ';
                        if (!good) {
                            NSLog(@"RealmSync: Connection[%lu]: Bad PROGRESS message from server",
                                  _ident);
                            [self closeAndTryToReconnectLater];
                            return;
                        }
                        NSNumber *sessionIdent2 = [NSNumber numberWithUnsignedInteger:sessionIdent];
                        [self handleProgressMessageWithSessionIdent:sessionIdent2
                                                      serverVersion:serverVersion
                                                      clientVersion:clientVersion];
                    }
                    else if (message_type == "alloc") {
                        // New unique file identifier pair from server.
                        unsigned sessionIdent = 0;
                        uint_fast64_t serverFileIdent = 0, clientFileIdent = 0;
                        char sp1, sp2, sp3;
                        parser >> sp1 >> sessionIdent >> sp2 >> serverFileIdent >> sp3 >>
                            clientFileIdent;
                        bool good = parser && parser.eof() && sp1 == ' ' && sp2 == ' ' &&
                            sp3 == ' ';
                        if (!good) {
                            NSLog(@"RealmSync: Connection[%lu]: Bad ALLOC message "
                                  "from server", _ident);
                            [self closeAndTryToReconnectLater];
                            return;
                        }
                        NSNumber *sessionIdent2 = [NSNumber numberWithUnsignedInteger:sessionIdent];
                        [self handleAllocMessageWithSessionIdent:sessionIdent2
                                                 serverFileIdent:serverFileIdent
                                                 clientFileIdent:clientFileIdent];
                    }
                    else {
                        NSLog(@"RealmSync: Connection[%lu]: Bad message from server", _ident);
                        [self closeAndTryToReconnectLater];
                        return;
                    }
                }

                // Message body
                if (_messageHandler) {
                    _messageBodyBuffer = [NSMutableData dataWithLength:_messageBodySize];
                    _messageBodyCurr = static_cast<char*>(_messageBodyBuffer.mutableBytes);
                  body:
                    char *messageBodyBegin = static_cast<char*>(_messageBodyBuffer.mutableBytes);
                    char *messageBodyEnd = messageBodyBegin + _messageBodySize;
                    size_t sourceAvail = inputEnd - inputBegin;
                    size_t destAvail = messageBodyEnd - _messageBodyCurr;
                    size_t avail = std::min(sourceAvail, destAvail);
                    const char *i = inputBegin + avail;
                    _messageBodyCurr = std::copy(inputBegin, i, _messageBodyCurr);
                    inputBegin = i;
                    if (_messageBodyCurr != messageBodyEnd) {
                        REALM_ASSERT(inputBegin == inputEnd);
                        break;
                    }
                    void (^messageHandler)();
                    messageHandler = _messageHandler;
                    _messageHandler = nil;
                    messageHandler();
                    if (!_isOpen)
                        return;
                }
                _inputIsHead = YES;
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable: {
            if (stream != _outputStream)
                return;
            REALM_ASSERT(_currentOutputChunk);
            const uint8_t *buffer = reinterpret_cast<const uint8_t *>(_currentOutputBegin);
            NSUInteger length = _currentOutputEnd - _currentOutputBegin;
            NSInteger n = [_outputStream write:buffer maxLength:length];
            if (n < 0) {
                NSLog(@"RealmSync: Connection[%lu]: Error writing to socket: %@",
                      _ident, _outputStream.streamError);
                [self closeAndTryToReconnectLater];
                return;
            }
            _currentOutputBegin += n;
            if (_currentOutputBegin == _currentOutputEnd) {
                BOOL more = [self resumeOutput];
                if (!more) {
                    _currentOutputChunk = 0;
                    [_outputStream removeFromRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
                }
            }
            break;
        }
        case NSStreamEventEndEncountered: {
            if (stream != _inputStream && stream != _outputStream)
                return;
          end_of_input:
            NSLog(@"RealmSync: Connection[%lu]: Server closed connection", _ident);
            [self closeAndTryToReconnectLater];
            return;
        }
        case NSStreamEventErrorOccurred: {
            if (stream != _inputStream && stream != _outputStream)
                return;
            NSLog(@"RealmSync: Connection[%lu]: Socket error: %@", _ident, stream.streamError);
            [self closeAndTryToReconnectLater];
            return;
        }
    }
}


- (void)handleAllocMessageWithSessionIdent:(NSNumber *)sessionIdent
                           serverFileIdent:(uint_fast64_t)serverFileIdent
                           clientFileIdent:(uint_fast64_t)clientFileIdent {
    typedef unsigned long long ulonglong;
    NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Received: ALLOC(%llu, %llu)", _ident,
          sessionIdent, ulonglong(serverFileIdent), ulonglong(clientFileIdent));

    RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
    if (!session)
        return; // This session no longer exists

    [session handleAllocMessageWithServerFileIdent:serverFileIdent
                                   clientFileIdent:clientFileIdent];
}


- (void)handleDownloadMessageWithSessionIdent:(NSNumber *)sessionIdent
                                serverVersion:(Replication::version_type)serverVersion
                                clientVersion:(Replication::version_type)clientVersion
                              originTimestamp:(uint_fast64_t)originTimestamp
                              originFileIdent:(uint_fast64_t)originFileIdent
                              moreIsAvailable:(bool)moreIsAvailable {
    if (s_syncLogEverything) {
        using ulong     = unsigned long;
        using ulonglong = unsigned long long;
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Received: DOWNLOAD(server_version=%llu, "
              "client_version=%llu, changeset_size=%lu, origin_timestamp=%llu, "
              "origin_file_ident=%llu, more_is_available=%d)", _ident, sessionIdent,
              ulonglong(serverVersion), ulonglong(clientVersion), ulong(_messageBodyBuffer.length),
              ulonglong(originTimestamp), ulonglong(originFileIdent), int(moreIsAvailable));
    }

    RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
    if (!session)
        return; // This session no longer exists

    NSData *changeset = _messageBodyBuffer;
    _messageBodyBuffer = nil;

    [session handleDownloadMessageWithServerVersion:serverVersion
                                      clientVersion:clientVersion
                                          changeset:changeset
                                    originTimestamp:originTimestamp
                                    originFileIdent:originFileIdent
                                    moreIsAvailable:moreIsAvailable];
}


- (void)handleProgressMessageWithSessionIdent:(NSNumber *)sessionIdent
                                serverVersion:(Replication::version_type)serverVersion
                                clientVersion:(Replication::version_type)clientVersion {
    if (s_syncLogEverything) {
        using ulonglong = unsigned long long;
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Received: PROGRESS(server_version=%llu, "
              "client_version=%llu)", _ident, sessionIdent, ulonglong(serverVersion),
              ulonglong(clientVersion));
    }

    RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
    if (!session)
        return; // This session no longer exists

    [session handleProgressMessageWithServerVersion:serverVersion clientVersion:clientVersion];
}

@end


@implementation RLMSyncSession {
    std::unique_ptr<SharedGroup>            _sharedGroup;
    std::unique_ptr<ClientTransformHistory> _history;

    std::unique_ptr<SharedGroup>            _backgroundSharedGroup; // For background thread
    std::unique_ptr<ClientTransformHistory> _backgroundHistory;     // For background thread
    std::unique_ptr<Transformer>            _backgroundTransformer; // For background thread

    Replication::version_type _latestVersionAvailable;
    Replication::version_type _latestVersionUploaded;
    Replication::version_type _progressServerVersion;
    Replication::version_type _progressClientVersion;
    Replication::version_type _persistedProgressServerVersion;
    Replication::version_type _persistedProgressClientVersion;
    Replication::version_type _serverVersionThreshold;
    BOOL _uploadInProgress;

    std::vector<Transformer::RemoteChangeset> _pendingChangesets;
    std::vector<NSData *> _pendingChangesetBuffers;

    NSOperationQueue *_backgroundOperationQueue;
}


- (instancetype)initWithConnection:(RLMServerConnection *)connection
                        serverPath:(NSString *)serverPath
                     configuration:(RLMRealmConfiguration *)configuration {
    self = [super init];
    if (self) {
        _connection = connection;
        _serverFileIdent = 0; // Assigned when `_clientFileIdent` is assigned
        _clientFileIdent = 0; // Zero means unassigned
        _serverPath = serverPath;
        _configuration = [configuration copy];
        _sessionIdent = [NSNumber numberWithUnsignedInteger:[connection newSessionIdent]];

        SharedGroup::DurabilityLevel durability = SharedGroup::durability_Full;
        _history = realm::make_client_transform_history(_configuration.path.UTF8String);
        _sharedGroup = std::make_unique<SharedGroup>(*_history, durability);
        _backgroundHistory = realm::make_client_transform_history(_configuration.path.UTF8String);
        _backgroundSharedGroup = std::make_unique<SharedGroup>(*_backgroundHistory, durability);
        _backgroundTransformer = realm::make_transformer(false, *_backgroundHistory);
        _backgroundOperationQueue = [[NSOperationQueue alloc] init];
        _backgroundOperationQueue.name = @"io.realm.sync";
        _backgroundOperationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}


- (void)mainThreadInit {
    // Called by main thread
    uint_fast64_t serverFileIdent, clientFileIdent;
    if (_history->get_file_ident_pair(serverFileIdent, clientFileIdent)) {
        _serverFileIdent = serverFileIdent;
        _clientFileIdent = clientFileIdent;
        _backgroundTransformer->set_local_client_file_ident(clientFileIdent);
    }

    _history->get_sync_progress(_persistedProgressServerVersion, _persistedProgressClientVersion);

    _latestVersionAvailable = LangBindHelper::get_current_version(*_sharedGroup);
    REALM_ASSERT(_latestVersionAvailable >= 1);
    REALM_ASSERT(_latestVersionAvailable >= _persistedProgressClientVersion);

    // It is possible to find an inconsistency between the main Realm file, and
    // the associated history file(s). In particular, since the server-side
    // progress, as persisted in the history file(s), is updated after
    // successful integration of an incoming changeset, it is possible to find
    // that a changeset has been downloaded and integrated into the Realm, but
    // that `_persisteedProgressServerVersion` has not been updated to reflect
    // it, presumably due to a a crash at an unfortunate point in time.
    //
    // FIXME: This possibility of inconsistency can be eliminated by moving the
    // history into the main Realm file, which is already something that is
    // likely to happen for different reasons.
    //
    // If a new synchronization session is started at a time where such an
    // inconsistency exists, the server will resend the changeset that was
    // already integrated, and it is therefore necessary for the client to be
    // able to reliably intercept and ignore a received changeset that is
    // already integrated. `_serverVersionThreshold` was introduced to solve
    // this problem.
    //
    // During initialization of a RLMSyncSession object,
    // `_serverVersionThreshold` is set to `HistoryEntry::remote_version` of the
    // last history entry, that succeeds `_persistedProgressClientVersion`, and
    // is produced by integration of a remote changeset, or if no such history
    // entry exists, it is set to `_persistedProgressServerVersion`.
    //
    // Given that, any changeset, that is received in a DOWNLOAD message
    // specifying a server version less than, or equal to
    // `_serverVersionThreshold`, is known to already have been integrated, and
    // can be safely ignored by the client.
    _serverVersionThreshold = _persistedProgressServerVersion;
    {
        HistoryEntry historyEntry;
        History::version_type version = _latestVersionAvailable;
        if (version == 1)
            version = 0;
        while (version > _persistedProgressClientVersion) {
            History::version_type prevVersion = _history->get_history_entry(version, historyEntry);
            BOOL isForeign = historyEntry.origin_client_file_ident != 0;
            if (isForeign) {
                _serverVersionThreshold = historyEntry.remote_version;
                break;
            }
            version = prevVersion;
        }
    }

    NSString *realmPath = _configuration.path;
    NSLog(@"RealmSync: Connection[%lu]: Session[%@]: New session for '%@'", _connection.ident,
          _sessionIdent, realmPath);

/*
    using ulonglong = unsigned long long;
    NSLog(@"_latestVersionAvailable = %llu", ulongong(_latestVersionAvailable));
    NSLog(@"_latestVersionUploaded = %llu",  ulongong(_latestVersionUploaded));
    NSLog(@"_progressServerVersion = %llu",  ulongong(_persistedProgressServerVersion));
    NSLog(@"_progressClientVersion = %llu",  ulongong(_persistedProgressClientVersion));
    NSLog(@"_serverVersionThreshold = %llu", ulongong(_serverVersionThreshold));
*/

    [_connection mainThreadInit];
    [_connection addSession:self];
}


- (void)refreshLatestVersionAvailable {
    _latestVersionAvailable = LangBindHelper::get_current_version(*_sharedGroup);
    if (_connection.isOpen && _clientFileIdent != 0)
        [self resumeUpload];
}


- (void)connectionIsOpen {
    if (_clientFileIdent != 0) {
        [self connectionIsOpenAndSessionHasFileIdent];
    }
    else {
        [_connection sendAllocMessageWithSessionIdent:_sessionIdent
                                           serverPath:_serverPath];
    }
}


- (void)connectionIsOpenAndSessionHasFileIdent {
    _pendingChangesets.clear();
    _pendingChangesetBuffers.clear();
    _progressServerVersion = _persistedProgressServerVersion;
    _progressClientVersion = _persistedProgressClientVersion;
    _latestVersionUploaded = std::max<History::version_type>(1, _progressClientVersion);
    if (_latestVersionUploaded > _latestVersionAvailable) // Transiently possible (FIXME: Or is it?)
        _latestVersionUploaded = _latestVersionAvailable;
    [_connection sendBindMessageWithSessionIdent:_sessionIdent
                                 serverFileIdent:_serverFileIdent
                                 clientFileIdent:_clientFileIdent
                                      serverPath:_serverPath
                                   serverVersion:_progressServerVersion
                                   clientVersion:_progressClientVersion];
    [self resumeUpload];
}


- (void)connectionIsClosed {
    _uploadInProgress = NO;
}


- (void)resumeUpload {
    REALM_ASSERT(_connection.isOpen && _clientFileIdent != 0);
    if (_uploadInProgress)
        return;
    _uploadInProgress = YES;

    // Fetch and copy the next changeset, and produce an output message from it.
    // Set the completionHandler to a block that calls resumeUpload.
    HistoryEntry::version_type uploadVersion;
    HistoryEntry historyEntry;
    for (;;) {
        REALM_ASSERT(_latestVersionUploaded <= _latestVersionAvailable);
        if (_latestVersionUploaded == _latestVersionAvailable) {
            _uploadInProgress = NO;
            return;
        }
        uploadVersion = _latestVersionUploaded + 1;
        _history->get_history_entry(uploadVersion, historyEntry);
        // Skip changesets that were downloaded from the server
        BOOL isForeign = historyEntry.origin_client_file_ident != 0;
        if (!isForeign)
            break;
        _latestVersionUploaded = uploadVersion;
    }
    using ulong     = unsigned long;
    using ulonglong = unsigned long long;
    // `serverVersion` is the last server version that has been integrated into
    // `uploadVersion`.
    auto clientVersion = uploadVersion;
    auto serverVersion = historyEntry.remote_version;
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.body = [NSData dataWithBytes:historyEntry.changeset.data()
                              length:historyEntry.changeset.size()]; // Full copy
    msg.head = [NSString stringWithFormat:@"upload %@ %llu %llu %lu %llu\n", _sessionIdent,
                         ulonglong(clientVersion), ulonglong(serverVersion),
                         ulong(msg.body.length), ulonglong(historyEntry.origin_timestamp)];
    if (s_syncLogEverything) {
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Sending: UPLOAD(client_version=%llu, "
              "server_version=%llu, changeset_size=%lu, timestamp=%llu)", _connection.ident,
              _sessionIdent, ulonglong(clientVersion), ulonglong(serverVersion),
              ulong(msg.body.length), ulonglong(historyEntry.origin_timestamp));
    }
    __weak RLMSyncSession *weakSelf = self;
    [msg setCompletionHandler:^{
            [weakSelf uploadCompletedWithVersion:uploadVersion];
        }];
    [_connection enqueueOutputMessage:msg];
}


- (void)uploadCompletedWithVersion:(Replication::version_type)version {
    REALM_ASSERT(version <= _latestVersionUploaded+1);
    _uploadInProgress = NO;
    if (_latestVersionUploaded < version)
        _latestVersionUploaded = version;
    if (_connection.isOpen)
        [self resumeUpload];
}


- (void)handleAllocMessageWithServerFileIdent:(uint_fast64_t)serverFileIdent
                              clientFileIdent:(uint_fast64_t)clientFileIdent {
    _history->set_file_ident_pair(serverFileIdent, clientFileIdent); // Save in persistent storage
    // FIXME: Describe what (if anything) prevents a race condition here, as a
    // naive analysis would suggest that the background thread could be
    // accessing _backgroundHistory concurrently. It would be tempting to
    // conclude that a race is not possible, because the background thread must
    // not attempt to transform anything before the file identifier is
    // known. Note that it cannot be assumed the there will be no spurious
    // ALLOC messages received.
    _backgroundTransformer->set_local_client_file_ident(clientFileIdent);
    _serverFileIdent = serverFileIdent;
    _clientFileIdent = clientFileIdent;
    if (_connection.isOpen)
        [self connectionIsOpenAndSessionHasFileIdent];
}


- (void)handleDownloadMessageWithServerVersion:(Replication::version_type)serverVersion
                                 clientVersion:(Replication::version_type)clientVersion
                                     changeset:(NSData *)changeset
                               originTimestamp:(uint_fast64_t)originTimestamp
                               originFileIdent:(uint_fast64_t)originFileIdent
                               moreIsAvailable:(bool)moreIsAvailable {
    // We cannot save the synchronization progress marker (`serverVersion`,
    // `clientVersion`) to persistent storage until the changeset is actually
    // integrated locally, but that means it will be delayed by two context
    // switches, i.e., first by a switch to the background thread, and then by a
    // switch back to the main thread, and in each of these switches there is a
    // risk of termination of the flow of this information due to a severed weak
    // reference, which presumably would be due to the termination of the
    // synchronization session, but not necessarily in connection with the
    // termination of the application.
    bool good_versions =
        serverVersion >  _progressServerVersion &&
        clientVersion >= _progressClientVersion;
    if (!good_versions) {
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: ERROR: Bad server and/or client version "
              "in DOWNLOAD message", _connection.ident, _sessionIdent);
        [_connection closeAndTryToReconnectLater];
        return;

    }
    _progressServerVersion = serverVersion;
    _progressClientVersion = clientVersion;

    // Skip changesets that were already integrated during an earlier session,
    // but still attempt to save a new synchronization progress marker to
    // persistent storage.
    if (serverVersion > _serverVersionThreshold) {
        BinaryData data(static_cast<const char *>(changeset.bytes), size_t(changeset.length));
        Transformer::RemoteChangeset changeset_2(serverVersion, clientVersion, data,
                                                 originTimestamp, originFileIdent);
        REALM_ASSERT(_pendingChangesets.size() <= _pendingChangesetBuffers.size());
        _pendingChangesetBuffers.reserve(_pendingChangesets.size()+1); // Throws
        _pendingChangesets.push_back(changeset_2); // Throws
        _pendingChangesetBuffers.push_back(std::move(changeset)); // Not throwing
    }
    else {
        if (s_syncLogEverything) {
            using ulonglong = unsigned long long;
            NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Ignoring previously integrated "
                  "changeset (server version threshold is %llu)", _connection.ident, _sessionIdent,
                  ulonglong(_serverVersionThreshold));
        }
    }

    // FIXME: Also "flush" the "pending queue" if the accumulated size exceeds a
    // certain limit. Additionally, when adding the first changeset to the
    // "pending queue", start a deadline timer, and flush on timeout
    // (cancel/restart the timer on early flush).

    if (moreIsAvailable)
        return;

    std::vector<Transformer::RemoteChangeset> changesets = std::move(_pendingChangesets);
    std::vector<NSData *> changesetBuffers               = std::move(_pendingChangesetBuffers);
    _pendingChangesets.clear();
    _pendingChangesetBuffers.clear();
    [self addBackgroundTaskWithServerVersion:serverVersion
                               clientVersion:clientVersion
                                  changesets:std::move(changesets)
                            changesetBuffers:std::move(changesetBuffers)];
}


- (void)handleProgressMessageWithServerVersion:(Replication::version_type)serverVersion
                                 clientVersion:(Replication::version_type)clientVersion {
    // As with DOWNLOAD messages, we need to update the synchronization progress
    // marker.
    //
    // FIXME: Properly explain the three roles of the synchronization progress
    // marker (syncronization restart point, history upload window specifier,
    // and history merge window specifier), and the intricate interplay between
    // them.
    bool good_versions =
        serverVersion >  _progressServerVersion &&
        clientVersion >= _progressClientVersion;
    if (!good_versions) {
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: ERROR: Bad server and/or client version "
              "in PROGRESS message", _connection.ident, _sessionIdent);
        [_connection closeAndTryToReconnectLater];
        return;

    }

    if (!_pendingChangesets.empty()) {
        NSLog(@"RealmSync: Connection[%lu]: Session(%@): ERROR: PROGRESS message received while "
              "changesets are pending", _connection.ident, _sessionIdent);
        [_connection closeAndTryToReconnectLater];
        return;
    }

    _progressServerVersion = serverVersion;
    _progressClientVersion = clientVersion;

    std::vector<Transformer::RemoteChangeset> changesets;
    std::vector<NSData *> changesetBuffers;
    [self addBackgroundTaskWithServerVersion:serverVersion
                               clientVersion:clientVersion
                                  changesets:std::move(changesets)
                            changesetBuffers:std::move(changesetBuffers)];
}


- (void)addBackgroundTaskWithServerVersion:(Replication::version_type)serverVersion
                             clientVersion:(Replication::version_type)clientVersion
                                changesets:(std::vector<Transformer::RemoteChangeset>)changesets
                          changesetBuffers:(std::vector<NSData *>)changesetBuffers {
    __weak RLMSyncSession *weakSelf = self;
    [_backgroundOperationQueue addOperationWithBlock:^{
            [weakSelf backgroundTaskWithServerVersion:serverVersion
                                        clientVersion:clientVersion
                                           changesets:std::move(changesets)
                                     changesetBuffers:std::move(changesetBuffers)];
        }];
}


- (void)backgroundTaskWithServerVersion:(Replication::version_type)serverVersion
                          clientVersion:(Replication::version_type)clientVersion
                             changesets:(std::vector<Transformer::RemoteChangeset>)changesets
                       changesetBuffers:(std::vector<NSData *>)changesetBuffers {
    if (!changesets.empty())
        [self backgroundApplyChangesets:changesets];
    static_cast<void>(changesetBuffers); // Still the owner of the changeset buffer memory

    __weak RLMSyncSession *weakSelf = self;
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [mainQueue addOperationWithBlock:^{
            [weakSelf updateSyncProgressWithServerVersion:serverVersion
                                            clientVersion:clientVersion];
        }];
}


- (void)backgroundApplyChangesets:(const std::vector<Transformer::RemoteChangeset> &)changesets {
    REALM_ASSERT(!changesets.empty());
    const Transformer::RemoteChangeset *changesets_2 = changesets.data();
    size_t numChangesets = changesets.size();
    Replication::version_type newClientVersion;
    try {
        Transformer &transformer = *_backgroundTransformer;
        SharedGroup& sharedGroup = *_backgroundSharedGroup;
        util::Logger* replayLogger = 0;
        newClientVersion =
            transformer.integrate_remote_changesets(sharedGroup, changesets_2, numChangesets,
                                                    replayLogger); // Throws
    }
    catch (TransformError& e) {
        NSString *message = [NSString stringWithFormat:@"Bad changeset received: %s", e.what()];
        @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil];
    }

    [RLMRealm realmWithConfiguration:_configuration error:nullptr]->_realm->notify_others();

    if (s_syncLogEverything) {
        using ulong     = unsigned long;
        using ulonglong = unsigned long long;
        if (numChangesets == 1) {
            NSLog(@"RealmSync: Connection[%lu]: Session[%@]: 1 remote changeset integrated, "
                  "producing client version %llu", _connection.ident, _sessionIdent,
                  ulonglong(newClientVersion));
        }
        else {
            NSLog(@"RealmSync: Connection[%lu]: Session[%@]: %lu remote changesets integrated, "
                  "producing client version %llu", _connection.ident, _sessionIdent,
                  ulong(numChangesets), ulonglong(newClientVersion));
        }
    }
}


- (void)updateSyncProgressWithServerVersion:(Replication::version_type)serverVersion
                              clientVersion:(Replication::version_type)clientVersion {
    _history->set_sync_progress(serverVersion, clientVersion);
    _persistedProgressServerVersion = serverVersion;
    _persistedProgressClientVersion = clientVersion;
}


- (void)dealloc {
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    __weak RLMServerConnection *weakConnection = _connection;
    NSNumber *sessionIdent = _sessionIdent;
    [mainQueue addOperationWithBlock:^{
            [weakConnection sendUnbindMessageWithSessionIdent:sessionIdent];
        }];
}

@end


@interface RLMRealmConfiguration ()
- (realm::Realm::Config&)config;
@end

@interface RLMRealm ()
- (void)sendNotifications:(NSString *)notification;
@end

void RLMDisableSyncToDisk() {
    realm::disable_sync_to_disk();
}

// Notification Token
@interface RLMNotificationToken ()
@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, copy) RLMNotificationBlock block;
@end

@implementation RLMNotificationToken
- (void)dealloc
{
    if (_realm || _block) {
        NSLog(@"RLMNotificationToken released without unregistering a notification. You must hold "
              @"on to the RLMNotificationToken returned from addNotificationBlock and call "
              @"removeNotification: when you no longer wish to recieve RLMRealm notifications.");
    }
}
@end

static bool shouldForciblyDisableEncryption() {
    static bool disableEncryption = getenv("REALM_DISABLE_ENCRYPTION");
    return disableEncryption;
}

NSData *RLMRealmValidatedEncryptionKey(NSData *key) {
    if (shouldForciblyDisableEncryption()) {
        return nil;
    }

    if (key) {
        if (key.length != 64) {
            @throw RLMException(@"Encryption key must be exactly 64 bytes long");
        }
        if (RLMIsDebuggerAttached()) {
            @throw RLMException(@"Cannot open an encrypted Realm with a debugger attached to the process");
        }
#if TARGET_OS_WATCH
        @throw RLMException(@"Cannot open an encrypted Realm on watchOS.");
#endif
    }

    return key;
}

@implementation RLMRealm {
    NSHashTable *_collectionEnumerators;
    NSHashTable *_notificationHandlers;

    RLMSyncSession *_syncSession;
}

+ (BOOL)isCoreDebug {
    return realm::Version::has_feature(realm::feature_Debug);
}

+ (void)initialize {
    static bool initialized;
    if (initialized) {
        return;
    }
    initialized = true;

    RLMCheckForUpdates();
    RLMInstallUncaughtExceptionHandler();
    RLMSendAnalytics();
}

- (BOOL)isEmpty {
    return realm::ObjectStore::is_empty(self.group);
}

- (void)verifyThread {
    _realm->verify_thread();
}

- (BOOL)inWriteTransaction {
    return _realm->is_in_transaction();
}

- (NSString *)path {
    return @(_realm->config().path.c_str());
}

- (realm::Group *)group {
    return _realm->read_group();
}

- (BOOL)isReadOnly {
    return _realm->config().read_only;
}

-(BOOL)autorefresh {
    return _realm->auto_refresh();
}

- (void)setAutorefresh:(BOOL)autorefresh {
    _realm->set_auto_refresh(autorefresh);
}

+ (NSString *)writeableTemporaryPathForFile:(NSString *)fileName {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

+ (instancetype)defaultRealm {
    return [RLMRealm realmWithConfiguration:[RLMRealmConfiguration rawDefaultConfiguration] error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.path = path;
    return [RLMRealm realmWithConfiguration:configuration error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
                          key:(NSData *)key
                     readOnly:(BOOL)readonly
                     inMemory:(BOOL)inMemory
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError
{
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    if (inMemory) {
        configuration.inMemoryIdentifier = path.lastPathComponent;
    }
    else {
        configuration.path = path;
    }
    configuration.encryptionKey = key;
    configuration.readOnly = readonly;
    configuration.dynamic = dynamic;
    configuration.customSchema = customSchema;
    return [RLMRealm realmWithConfiguration:configuration error:outError];
}

// ARC tries to eliminate calls to autorelease when the value is then immediately
// returned, but this results in significantly different semantics between debug
// and release builds for RLMRealm, so force it to always autorelease.
static id RLMAutorelease(id value) {
    // +1 __bridge_retained, -1 CFAutorelease
    return value ? (__bridge id)CFAutorelease((__bridge_retained CFTypeRef)value) : nil;
}

static void RLMCopyColumnMapping(RLMObjectSchema *targetSchema, const ObjectSchema &tableSchema) {
    REALM_ASSERT_DEBUG(targetSchema.properties.count == tableSchema.properties.size());

    // copy updated column mapping
    for (auto const& prop : tableSchema.properties) {
        RLMProperty *targetProp = targetSchema[@(prop.name.c_str())];
        targetProp.column = prop.table_column;
    }

    // re-order properties
    [targetSchema sortPropertiesByColumn];
}

static void RLMRealmSetSchemaAndAlign(RLMRealm *realm, RLMSchema *targetSchema) {
    realm.schema = targetSchema;
    for (auto const& aligned : *realm->_realm->config().schema) {
        if (RLMObjectSchema *objectSchema = [targetSchema schemaForClassName:@(aligned.name.c_str())]) {
            objectSchema.realm = realm;
            RLMCopyColumnMapping(objectSchema, aligned);
        }
    }
}

+ (instancetype)realmWithSharedRealm:(SharedRealm)sharedRealm schema:(RLMSchema *)schema {
    RLMRealm *realm = [RLMRealm new];
    realm->_realm = sharedRealm;
    realm->_dynamic = YES;
    RLMRealmSetSchemaAndAlign(realm, schema);
    return RLMAutorelease(realm);
}

+ (SharedRealm)openSharedRealm:(Realm::Config const&)config error:(NSError **)outError {
    try {
        return Realm::get_shared_realm(config);
    }
    catch (RealmFileException const& ex) {
        switch (ex.kind()) {
            case RealmFileException::Kind::PermissionDenied:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFilePermissionDenied, ex), outError);
                break;
            case RealmFileException::Kind::IncompatibleLockFile: {
                NSString *err = @"Realm file is currently open in another process "
                                 "which cannot share access with this process. All "
                                 "processes sharing a single file must be the same "
                                 "architecture. For sharing files between the Realm "
                                 "Browser and an iOS simulator, this means that you "
                                 "must use a 64-bit simulator.";
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorIncompatibleLockFile, File::PermissionDenied(err.UTF8String, "FIXME: ex.get_path()")), outError);
                break;
            }
            case RealmFileException::Kind::Exists:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileExists, ex), outError);
                break;
            case RealmFileException::Kind::AccessError:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFileAccessError, ex), outError);
                break;
            default:
                RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, ex), outError);
                break;
        }
    }
    catch (std::system_error const& ex) {
        RLMSetErrorOrThrow(RLMMakeError(ex), outError);
    }
    catch (const std::exception &exp) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, exp), outError);
    }
    return nullptr;
}

+ (instancetype)realmWithConfiguration:(RLMRealmConfiguration *)configuration error:(NSError **)error {
    configuration = [configuration copy];
    Realm::Config& config = configuration.config;

    bool dynamic = configuration.dynamic;
    bool readOnly = configuration.readOnly;

    // try to reuse existing realm first
    if (config.cache || dynamic) {
        RLMRealm *realm = RLMGetThreadLocalCachedRealmForPath(config.path);
        if (realm) {
            auto const& old_config = realm->_realm->config();
            if (old_config.read_only != config.read_only) {
                @throw RLMException(@"Realm at path '%s' already opened with different read permissions", config.path.c_str());
            }
            if (old_config.in_memory != config.in_memory) {
                @throw RLMException(@"Realm at path '%s' already opened with different inMemory settings", config.path.c_str());
            }
            if (realm->_dynamic != dynamic) {
                @throw RLMException(@"Realm at path '%s' already opened with different dynamic settings", config.path.c_str());
            }
            if (old_config.encryption_key != config.encryption_key) {
                @throw RLMException(@"Realm at path '%s' already opened with different encryption key", config.path.c_str());
            }
            return RLMAutorelease(realm);
        }
    }

    RLMRealm *realm = [RLMRealm new];
    realm->_dynamic = dynamic;

    auto migrationBlock = configuration.migrationBlock;
    if (migrationBlock && config.schema_version > 0) {
        auto customSchema = configuration.customSchema;
        config.migration_function = [=](SharedRealm old_realm, SharedRealm realm) {
            RLMSchema *oldSchema = [RLMSchema dynamicSchemaFromObjectStoreSchema:*old_realm->config().schema];
            RLMRealm *oldRealm = [RLMRealm realmWithSharedRealm:old_realm schema:oldSchema];

            // The destination RLMRealm can't just use the schema from the
            // SharedRealm because it doesn't have information about whether or
            // not a class was defined in Swift, which effects how new objects
            // are created
            RLMSchema *newSchema = [customSchema ?: RLMSchema.sharedSchema copy];
            RLMRealm *newRealm = [RLMRealm realmWithSharedRealm:realm schema:newSchema];

            [[[RLMMigration alloc] initWithRealm:newRealm oldRealm:oldRealm] execute:migrationBlock];

            oldRealm->_realm = nullptr;
            newRealm->_realm = nullptr;
        };
    }
    else {
        config.migration_function = [](SharedRealm, SharedRealm) { };
    }

    // protects the realm cache and accessors cache
    static id initLock = [NSObject new];
    @synchronized(initLock) {
        realm->_realm = [self openSharedRealm:config error:error];
        if (!realm->_realm) {
            return nil;
        }

        // if we have a cached realm on another thread, copy without a transaction
        if (RLMRealm *cachedRealm = RLMGetAnyCachedRealmForPath(config.path)) {
            realm.schema = [cachedRealm.schema shallowCopy];
            for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
                objectSchema.realm = realm;
            }

            if (realm.configuration.syncServerURL) {
                if (![realm.configuration.syncServerURL isEqual:cachedRealm.configuration.syncServerURL]) {
                    @throw [NSException exceptionWithName:@"RLMException"
                                                   reason:@"Server synchronization URL mismatch"
                                                 userInfo:nil];
                }
                realm->_syncSession = cachedRealm->_syncSession;
            }
        }
        else {
            // FIXME: A file cannot be reliably identified by its path. A
            // safe approach is to start by opening the file, then get the
            // inode and device numbers from the file descriptor, then use
            // that pair as a key to lookup a preexisting RLMRealm
            // instance. If one is found, the opened file can be closed. If
            // one is not found, a new RLMRealm instance can be created from
            // the handle of the open file. Alternatively, on a system with
            // a proc filesystem, on can use the path to the file descriptor
            // as a basis for constructing the new RLMInstance. Note that
            // the inode number is only guaranteed to stay valid for as long
            // as you hold on the the handle of the open file.
            RLMSyncSession *session = [s_syncSessions objectForKey:realm.path];
            if (!session) {
                if (NSURL *serverBaseURL = realm.configuration.syncServerURL) {
                    NSString *hostKey = serverBaseURL.host;
                    if (serverBaseURL.port) {
                        hostKey = [NSString stringWithFormat:@"%@:%@", serverBaseURL.host, serverBaseURL.port];
                    }
                    RLMServerConnection *conn = [s_serverConnections objectForKey:hostKey];
                    if (!conn) {
                        unsigned long serverConnectionIdent = ++s_lastServerConnectionIdent;
                        conn = [[RLMServerConnection alloc] initWithIdent:serverConnectionIdent
                                                                 identity:realm.configuration.syncIdentity
                                                                  address:serverBaseURL.host
                                                                     port:serverBaseURL.port];
                        [s_serverConnections setObject:conn forKey:hostKey];
                    }
                    session = [[RLMSyncSession alloc] initWithConnection:conn
                                                              serverPath:serverBaseURL.path
                                                           configuration:realm.configuration];
                    [s_syncSessions setObject:session forKey:realm.path];
                    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
                    __weak RLMSyncSession *weakSession = session;
                    [mainQueue addOperationWithBlock:^{
                        [weakSession mainThreadInit];
                    }];
                }
            }
            realm->_syncSession = session;

            try {
                // set/align schema or perform migration if needed
                RLMSchema *schema = [configuration.customSchema copy];
                if (!schema) {
                    if (dynamic) {
                        schema = [RLMSchema dynamicSchemaFromObjectStoreSchema:*realm->_realm->config().schema];
                    }
                    else {
                        schema = [RLMSchema.sharedSchema copy];
                        realm->_realm->update_schema(schema.objectStoreCopy, config.schema_version);
                    }
                }

                RLMRealmSetSchemaAndAlign(realm, schema);
            } catch (std::exception const& exception) {
                RLMSetErrorOrThrow(RLMMakeError(RLMException(exception)), error);
                return nil;
            }

            if (!dynamic || configuration.customSchema) {
                RLMRealmCreateAccessors(realm.schema);
            }
        }

        if (config.cache) {
            RLMCacheRealm(config.path, realm);
        }
    }

    if (!readOnly) {
        // initializing the schema started a read transaction, so end it
        [realm invalidate];
        realm->_realm->m_binding_context = RLMCreateBindingContext(realm);
    }

    return RLMAutorelease(realm);
}

+ (void)resetRealmState {
    RLMClearRealmCache();
    realm::Realm::s_global_cache.clear();
    [RLMRealmConfiguration resetRealmConfigurationState];
}

static void CheckReadWrite(RLMRealm *realm, NSString *msg=@"Cannot write to a read-only Realm") {
    if (realm.readOnly) {
        @throw RLMException(@"%@", msg);
    }
}

- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block {
    [self verifyThread];
    CheckReadWrite(self, @"Read-only Realms do not change and do not have change notifications");
    if (!block) {
        @throw RLMException(@"The notification block should not be nil");
    }

    _realm->read_group();

    if (!_notificationHandlers) {
        _notificationHandlers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }

    RLMNotificationToken *token = [[RLMNotificationToken alloc] init];
    token.realm = self;
    token.block = block;
    [_notificationHandlers addObject:token];
    return token;
}

- (void)removeNotification:(RLMNotificationToken *)token {
    [self verifyThread];
    if (token) {
        [_notificationHandlers removeObject:token];
        token.realm = nil;
        token.block = nil;
    }
}

- (void)sendNotifications:(NSString *)notification {
    NSAssert(!self.readOnly, @"Read-only realms do not have notifications");

    if ([notification isEqualToString:RLMRealmDidChangeNotification]) {
        __weak RLMSyncSession *weakSession = _syncSession;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [weakSession refreshLatestVersionAvailable];
        }];
    }

    // call this realms notification blocks
    for (RLMNotificationToken *token in [_notificationHandlers allObjects]) {
        if (token.block) {
            token.block(notification, self);
        }
    }
}

- (RLMRealmConfiguration *)configuration {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.config = _realm->config();
    configuration.dynamic = _dynamic;
    configuration.customSchema = _schema;
    return configuration;
}

- (void)beginWriteTransaction {
    try {
        _realm->begin_transaction();
    }
    catch (std::exception &ex) {
        @throw RLMException(ex);
    }

    // notify any collections currently being enumerated that they need
    // to switch to enumerating a copy as the data may change on them
    for (RLMFastEnumerator *enumerator in _collectionEnumerators) {
        [enumerator detach];
    }
    _collectionEnumerators = nil;
}

- (void)commitWriteTransaction {
    [self commitWriteTransaction:nil];
}

- (BOOL)commitWriteTransaction:(NSError **)outError {
    try {
        _realm->commit_transaction();
        return YES;
    }
    catch (std::exception const& ex) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, ex), outError);
        return NO;
    }
}

- (void)transactionWithBlock:(void(^)(void))block {
    [self transactionWithBlock:block error:nil];
}

- (BOOL)transactionWithBlock:(void(^)(void))block error:(NSError **)outError {
    [self beginWriteTransaction];
    block();
    if (_realm->is_in_transaction()) {
        return [self commitWriteTransaction:outError];
    }
    return YES;
}

- (void)cancelWriteTransaction {
    try {
        _realm->cancel_transaction();
    }
    catch (std::exception &ex) {
        @throw RLMException(ex);
    }
}

- (void)invalidate {
    if (_realm->is_in_transaction()) {
        NSLog(@"WARNING: An RLMRealm instance was invalidated during a write "
              "transaction and all pending changes have been rolled back.");
    }

    for (RLMObjectSchema *objectSchema in _schema.objectSchema) {
        for (RLMObservationInfo *info : objectSchema->_observedObjects) {
            info->willChange(RLMInvalidatedKey);
        }
    }

    _realm->invalidate();

    for (RLMObjectSchema *objectSchema in _schema.objectSchema) {
        for (RLMObservationInfo *info : objectSchema->_observedObjects) {
            info->didChange(RLMInvalidatedKey);
        }
        objectSchema.table = nullptr;
    }
}

/**
 Replaces all string columns in this Realm with a string enumeration column and compacts the
 database file.
 
 Cannot be called from a write transaction.

 Compaction will not occur if other `RLMRealm` instances exist.
 
 While compaction is in progress, attempts by other threads or processes to open the database will
 wait.
 
 Be warned that resource requirements for compaction is proportional to the amount of live data in
 the database.
 
 Compaction works by writing the database contents to a temporary database file and then replacing
 the database with the temporary one. The name of the temporary file is formed by appending
 `.tmp_compaction_space` to the name of the database.

 @return YES if the compaction succeeded.
 */
- (BOOL)compact {
    // compact() automatically ends the read transaction, but we need to clean
    // up cached state and send invalidated notifications when that happens, so
    // explicitly end it first unless we're in a write transaction (in which
    // case compact() will throw an exception)
    if (!_realm->is_in_transaction()) {
        [self invalidate];
    }

    try {
        return _realm->compact();
    }
    catch (std::exception const& ex) {
        @throw RLMException(ex);
    }
}

- (void)dealloc {
    if (_realm) {
        if (_realm->is_in_transaction()) {
            [self cancelWriteTransaction];
            NSLog(@"WARNING: An RLMRealm instance was deallocated during a write transaction and all "
                  "pending changes have been rolled back. Make sure to retain a reference to the "
                  "RLMRealm for the duration of the write transaction.");
        }
    }
}

- (void)notify {
    _realm->notify();
}

- (BOOL)refresh {
    return _realm->refresh();
}

- (void)addObject:(__unsafe_unretained RLMObject *const)object {
    RLMAddObjectToRealm(object, self, false);
}

- (void)addObjects:(id<NSFastEnumeration>)array {
    for (RLMObject *obj in array) {
        if (![obj isKindOfClass:[RLMObject class]]) {
            @throw RLMException(@"Cannot insert objects of type %@ with addObjects:. Only RLMObjects are supported.",
                                NSStringFromClass(obj.class));
        }
        [self addObject:obj];
    }
}

- (void)addOrUpdateObject:(RLMObject *)object {
    // verify primary key
    if (!object.objectSchema.primaryKeyProperty) {
        @throw RLMException(@"'%@' does not have a primary key and can not be updated", object.objectSchema.className);
    }

    RLMAddObjectToRealm(object, self, true);
}

- (void)addOrUpdateObjectsFromArray:(id)array {
    for (RLMObject *obj in array) {
        [self addOrUpdateObject:obj];
    }
}

- (void)deleteObject:(RLMObject *)object {
    RLMDeleteObjectFromRealm(object, self);
}

- (void)deleteObjects:(id)array {
    if ([array respondsToSelector:@selector(realm)] && [array respondsToSelector:@selector(deleteObjectsFromRealm)]) {
        if (self != (RLMRealm *)[array realm]) {
            @throw RLMException(@"Can only delete objects from the Realm they belong to.");
        }
        [array deleteObjectsFromRealm];
    }
    else if ([array conformsToProtocol:@protocol(NSFastEnumeration)]) {
        for (id obj in array) {
            if ([obj isKindOfClass:RLMObjectBase.class]) {
                RLMDeleteObjectFromRealm(obj, self);
            }
        }
    }
    else {
        @throw RLMException(@"Invalid array type - container must be an RLMArray, RLMArray, or NSArray of RLMObjects");
    }
}

- (void)deleteAllObjects {
    RLMDeleteAllObjectsFromRealm(self);
}

- (RLMResults *)allObjects:(NSString *)objectClassName {
    return RLMGetObjects(self, objectClassName, nil);
}

- (RLMResults *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat, ... {
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objects:objectClassName where:predicateFormat args:args];
}

- (RLMResults *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat args:(va_list)args {
    return [self objects:objectClassName withPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (RLMResults *)objects:(NSString *)objectClassName withPredicate:(NSPredicate *)predicate {
    return RLMGetObjects(self, objectClassName, predicate);
}

- (RLMObject *)objectWithClassName:(NSString *)className forPrimaryKey:(id)primaryKey {
    return RLMGetObject(self, className, primaryKey);
}

+ (uint64_t)schemaVersionAtPath:(NSString *)realmPath error:(NSError **)error {
    return [RLMRealm schemaVersionAtPath:realmPath encryptionKey:nil error:error];
}

+ (uint64_t)schemaVersionAtPath:(NSString *)realmPath encryptionKey:(NSData *)key error:(NSError **)outError {
    try {
        RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
        config.path = realmPath;
        config.encryptionKey = RLMRealmValidatedEncryptionKey(key);

        uint64_t version = Realm::get_schema_version(config.config);
        if (version == realm::ObjectStore::NotVersioned) {
            RLMSetErrorOrThrow([NSError errorWithDomain:RLMErrorDomain code:RLMErrorFail userInfo:@{NSLocalizedDescriptionKey:@"Cannot open an uninitialized realm in read-only mode"}], outError);
        }
        return version;
    }
    catch (std::exception &exp) {
        RLMSetErrorOrThrow(RLMMakeError(RLMErrorFail, exp), outError);
        return RLMNotVersioned;
    }
}

+ (NSError *)migrateRealm:(RLMRealmConfiguration *)configuration {
    if (RLMGetAnyCachedRealmForPath(configuration.config.path)) {
        @throw RLMException(@"Cannot migrate Realms that are already open.");
    }

    @autoreleasepool {
        NSError *error;
        [RLMRealm realmWithConfiguration:configuration error:&error];
        return error;
    }
}

- (RLMObject *)createObject:(NSString *)className withValue:(id)value {
    return (RLMObject *)RLMCreateObjectInRealmWithValue(self, className, value, false);
}

- (BOOL)writeCopyToPath:(NSString *)path key:(NSData *)key error:(NSError **)error {
    key = RLMRealmValidatedEncryptionKey(key);

    try {
        self.group->write(path.UTF8String, static_cast<const char *>(key.bytes));
        return YES;
    }
    catch (File::PermissionDenied &ex) {
        if (error) {
            *error = RLMMakeError(RLMErrorFilePermissionDenied, ex);
        }
    }
    catch (File::Exists &ex) {
        if (error) {
            *error = RLMMakeError(RLMErrorFileExists, ex);
        }
    }
    catch (File::AccessError &ex) {
        if (error) {
            *error = RLMMakeError(RLMErrorFileAccessError, ex);
        }
    }
    catch (std::exception &ex) {
        if (error) {
            *error = RLMMakeError(RLMErrorFail, ex);
        }
    }

    return NO;
}

- (BOOL)writeCopyToPath:(NSString *)path error:(NSError **)error {
    return [self writeCopyToPath:path key:nil error:error];
}

- (BOOL)writeCopyToPath:(NSString *)path encryptionKey:(NSData *)key error:(NSError **)error {
    if (!key) {
        @throw RLMException(@"Encryption key must not be nil");
    }

    return [self writeCopyToPath:path key:key error:error];
}

- (void)registerEnumerator:(RLMFastEnumerator *)enumerator {
    if (!_collectionEnumerators) {
        _collectionEnumerators = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    [_collectionEnumerators addObject:enumerator];
}

- (void)unregisterEnumerator:(RLMFastEnumerator *)enumerator {
    [_collectionEnumerators removeObject:enumerator];
}

+ (void)setGlobalSynchronizationLoggingLevel:(RLMSyncLogLevel)level {
    s_syncLogEverything = level == RLMSyncLogLevelLudicrous;
}

@end
