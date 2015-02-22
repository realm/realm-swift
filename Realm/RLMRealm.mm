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
#import "RLMSchema_Private.h"
#import "RLMObject_Private.h"
#import "RLMArray_Private.hpp"
#import "RLMMigration_Private.h"
#import "RLMConstants.h"
#import "RLMObjectStore.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMUpdateChecker.hpp"
#import "RLMUtil.hpp"

#include <atomic>
#include <sstream>
#include <exception>
#include <sys/types.h>
#include <sys/sysctl.h>

#include <tightdb/util/memory_stream.hpp>
#include <tightdb/version.hpp>
#include <tightdb/group_shared.hpp>
#include <tightdb/commit_log.hpp>
#include <tightdb/lang_bind_helper.hpp>

// Notification Token

@interface RLMNotificationToken ()
@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, copy) RLMNotificationBlock block;
@end

@implementation RLMNotificationToken
- (void)dealloc
{
    if (_realm || _block) {
        NSLog(@"RLMNotificationToken released without unregistering a notification. You must hold \
              on to the RLMNotificationToken returned from addNotificationBlock and call \
              removeNotification: when you no longer wish to recieve RLMRealm notifications.");
    }
}
@end

// A weak holder for an RLMRealm to allow calling performSelector:onThread: without
// a strong reference to the realm
@interface RLMWeakNotifier : NSObject
@property (nonatomic, weak) RLMRealm *realm;

- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)notify;
@end

using namespace std;
using namespace tightdb;
using namespace tightdb::util;

namespace {

// create NSException from c++ exception
__attribute__((noreturn)) void throw_objc_exception(exception &ex) {
    NSString *errorMessage = [NSString stringWithUTF8String:ex.what()];
    @throw [NSException exceptionWithName:@"RLMException" reason:errorMessage userInfo:nil];
}

// create NSError from c++ exception
NSError *make_realm_error(RLMError code, exception &ex) {
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    [details setValue:[NSString stringWithUTF8String:ex.what()] forKey:NSLocalizedDescriptionKey];
    [details setValue:@(code) forKey:@"Error Code"];
    return [NSError errorWithDomain:@"io.realm" code:code userInfo:details];
}

//
// Global RLMRealm instance cache
//
NSMutableDictionary *s_realmsPerPath;
NSMutableDictionary *s_keysPerPath;

// FIXME: In the following 3 functions, we should be identifying files by the inode,device number pair
//  rather than by the path (since the path is not a reliable identifier). This requires additional support
//  from the core library though, because the inode,device number pair needs to be taken from the open file
//  (to avoid race conditions).
RLMRealm *cachedRealm(NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectForKey:@(threadID)];
    }
}

void cacheRealm(RLMRealm *realm, NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_realmsPerPath) {
        if (!s_realmsPerPath[path]) {
            s_realmsPerPath[path] = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsWeakMemory];
        }
        [s_realmsPerPath[path] setObject:realm forKey:@(threadID)];
    }
}

NSArray *realmsAtPath(NSString *path) {
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectEnumerator].allObjects;
    }
}

void clearRealmCache() {
    @synchronized(s_realmsPerPath) {
        for (NSMapTable *map in s_realmsPerPath.allValues) {
            [map removeAllObjects];
        }
        s_realmsPerPath = [NSMutableDictionary dictionary];
    }
    @synchronized(s_keysPerPath) {
        s_keysPerPath = [NSMutableDictionary dictionary];
    }
}

static NSString *s_defaultRealmPath = nil;
static RLMMigrationBlock s_migrationBlock;
static NSUInteger s_currentSchemaVersion = 0;

void createTablesInTransaction(RLMRealm *realm, RLMSchema *targetSchema) {
    [realm beginWriteTransaction];

    @try {
        RLMRealmCreateMetadataTables(realm);
        if (RLMRealmSchemaVersion(realm) == RLMNotVersioned) {
            RLMRealmSetSchemaVersion(realm, s_currentSchemaVersion);
        }
        RLMRealmCreateTables(realm, targetSchema, false);
    }
    @catch (NSException *) {
        [realm cancelWriteTransaction];
        @throw;
    }

    [realm commitWriteTransaction];
}

bool isDebuggerAttached() {
    int name[] = {
        CTL_KERN,
        KERN_PROC,
        KERN_PROC_PID,
        getpid()
    };

    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    if (sysctl(name, sizeof(name)/sizeof(name[0]), &info, &info_size, NULL, 0) == -1) {
        NSLog(@"sysctl() failed: %s", strerror(errno));
        return false;
    }


    return (info.kp_proc.p_flag & P_TRACED) != 0;
}

NSMutableDictionary *s_serverBaseURLS = [NSMutableDictionary dictionary];

// Access to s_syncSessions (referenced NSMapTable object), s_serverConnections
// (referenced NSMapTable object), and s_lastServerConnectionIdent, must be
// synchronized with respect to s_realmsPerPath.

// Maps local path to RLMSyncSession instance
NSMapTable *s_syncSessions = [NSMapTable strongToWeakObjectsMapTable];

// Maps "server:port" to RLMServerConnection instance
NSMapTable *s_serverConnections = [NSMapTable strongToWeakObjectsMapTable];

unsigned long s_lastServerConnectionIdent = 0;

atomic<bool> s_syncLogEverything(false);

} // anonymous namespace


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
@property (readonly, nonatomic) BOOL isOpen;
@end

@interface RLMSyncSession : NSObject
@property (readonly, nonatomic) RLMServerConnection *connection;
@property (readonly, nonatomic) NSNumber *sessionIdent;
@property (nonatomic) uint_fast64_t fileIdent;
@property (readonly, nonatomic) NSString *clientPath;
@property (readonly, nonatomic) NSString *serverPath;
- (void)connectionIsOpen;
- (void)handleIdentMessageWithFileIdent:(uint_fast64_t)fileIdent;
- (void)handleChangesetMessageWithServerVersion:(Replication::version_type)serverVersion
                                  clientVersion:(Replication::version_type)clientVersion
                                originTimestamp:(uint_fast64_t)originTimestamp
                                originFileIdent:(uint_fast64_t)originFileIdent
                                           data:(NSData *)data;
- (void)handleAcceptMessageWithServerVersion:(Replication::version_type)serverVersion
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
    unique_ptr<char[]> _inputBuffer;

    size_t _headBufferSize;
    unique_ptr<char[]> _headBuffer;
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


- (instancetype)initWithIdent:(unsigned long)ident address:(NSString *)address
                         port:(NSNumber *)port {
    self = [super init];
    if (self) {
        _ident = ident;
        _isOpen = NO;

        _address = address;
        _port = port ? port : [NSNumber numberWithInt:7800];

        _runLoop = nil;

        _inputBufferSize = 1024;
        _inputBuffer = make_unique<char[]>(_inputBufferSize);

        _headBufferSize = 192;
        _headBuffer = make_unique<char[]>(_headBufferSize);

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

    for (NSNumber *sessionIdent in _sessions) {
        RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
        [session connectionIsOpen];
    }
}


- (void)close {
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

    NSLog(@"RealmSync: Connection[%lu]: Closed", _ident);

    // FIXME: Retry opening the connection after a delay, maybe with a
    // progressively growing delay.
}


- (void)addSession:(RLMSyncSession *)session {
    [_sessions setObject:session forKey:session.sessionIdent];
    if (_isOpen)
        [session connectionIsOpen];
}


- (void)sendIdentMessageWithSessionIdent:(NSNumber *)sessionIdent
                              serverPath:(NSString *)serverPath {
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.body = [serverPath dataUsingEncoding:NSUTF8StringEncoding];
    msg.head = [NSString stringWithFormat:@"ident %@ %lu\n", sessionIdent, msg.body.length];
    [self enqueueOutputMessage:msg];
    NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Sending: Get unique client identifier for "
          "remote file '%@'", _ident, sessionIdent, serverPath);
}


- (void)sendBindMessageWithSessionIdent:(NSNumber *)sessionIdent
                              fileIdent:(uint_fast64_t)fileIdent
                          serverVersion:(Replication::version_type)serverVersion
                          clientVersion:(Replication::version_type)clientVersion
                             serverPath:(NSString *)serverPath
                             clientPath:(NSString *)clientPath {
    typedef unsigned long long ulonglong;
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.body = [serverPath dataUsingEncoding:NSUTF8StringEncoding];
    msg.head = [NSString stringWithFormat:@"bind %@ %llu %llu %llu %lu\n", sessionIdent,
                         ulonglong(fileIdent), ulonglong(serverVersion), ulonglong(clientVersion),
                         msg.body.length];
    [self enqueueOutputMessage:msg];
    NSLog(@"RealmSync: Connection[%lu]: Sessions[%@]: Sending: Bind local file '%@' "
          "with identifier %llu to remote file '%@' continuing synchronization from "
          "server version %llu, whose last integrated client version is %llu", _ident,
          sessionIdent, clientPath, ulonglong(fileIdent), serverPath, ulonglong(serverVersion),
          ulonglong(clientVersion));
}


- (void)sendUnbindMessageWithSessionIdent:(NSNumber *)sessionIdent {
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.head = [NSString stringWithFormat:@"unbind %@\n", sessionIdent];
    [self enqueueOutputMessage:msg];
    NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Sending: Unbind", _ident, sessionIdent);
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
                // FIXME: Report the error, close the connection, and try to
                // reconnect later
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
                    size_t avail = min(sourceAvail, destAvail);
                    const char *i = find(inputBegin, inputBegin + avail, '\n');
                    _headBufferCurr = copy(inputBegin, i, _headBufferCurr);
                    if (_headBufferCurr == headBufferEnd) {
                        NSLog(@"RealmSync: Connection[%lu]: Message head too big", _ident);
                        // FIXME: Report the error, close the connection, and
                        // try to reconnect later
                        return;
                    }
                    inputBegin = i;
                    if (inputBegin == inputEnd)
                        break;
                    ++inputBegin; // Discard newline from input
                    _inputIsHead = NO;

                    MemoryInputStream parser;
                    parser.set_buffer(headBufferBegin, _headBufferCurr);
                    _headBufferCurr = headBufferBegin;
                    parser.unsetf(std::ios_base::skipws);

                    string message_type;
                    parser >> message_type;

                    _messageHandler = nil;
                    __weak RLMServerConnection *weakSelf = self;
                    if (message_type == "changeset") {
                        // A new foreign changeset is available for download
                        unsigned sessionIdent = 0;
                        Replication::version_type serverVersion = 0;
                        Replication::version_type clientVersion = 0;
                        uint_fast64_t originTimestamp = 0;
                        uint_fast64_t originFileIdent = 0;
                        size_t changesetSize = 0;
                        char sp1, sp2, sp3, sp4, sp5, sp6;
                        parser >> sp1 >> sessionIdent >> sp2 >> serverVersion >> sp3 >>
                            clientVersion >> sp4 >> originTimestamp >> sp5 >>
                            originFileIdent >> sp6 >> changesetSize;
                        bool good = parser && parser.eof() && sp1 == ' ' && sp2 == ' ' &&
                            sp3 == ' ' && sp4 == ' ' && sp5 == ' ' && sp6 == ' ';
                        if (!good) {
                            NSLog(@"RealmSync: Connection[%lu]: Bad 'changeset' message "
                                  "from server", _ident);
                            // FIXME: Report the error, close the connection,
                            // and try to reconnect later
                            return;
                        }
                        _messageBodySize = changesetSize;
                        _messageHandler = ^{
                            NSNumber *sessionIdent2 = [NSNumber numberWithUnsignedInteger:sessionIdent];
                            [weakSelf handleChangesetMessageWithSessionIdent:sessionIdent2
                                                               serverVersion:serverVersion
                                                               clientVersion:clientVersion
                                                             originTimestamp:originTimestamp
                                                             originFileIdent:originFileIdent];
                        };
                    }
                    else if (message_type == "accept") {
                        // Server accepts a previously uploaded changeset
                        unsigned sessionIdent = 0;
                        Replication::version_type serverVersion = 0;
                        Replication::version_type clientVersion = 0;
                        char sp1, sp2, sp3;
                        parser >> sp1 >> sessionIdent >> sp2 >> serverVersion >> sp3 >>
                            clientVersion;
                        bool good = parser && parser.eof() && sp1 == ' ' && sp2 == ' ' &&
                            sp3 == ' ';
                        if (!good) {
                            NSLog(@"RealmSync: Connection[%lu]: Bad 'accept' message "
                                  "from server", _ident);
                            // FIXME: Report the error, close the connection,
                            // and try to reconnect later
                            return;
                        }
                        NSNumber *sessionIdent2 = [NSNumber numberWithUnsignedInteger:sessionIdent];
                        [self handleAcceptMessageWithSessionIdent:sessionIdent2
                                                    serverVersion:serverVersion
                                                    clientVersion:clientVersion];
                    }
                    else if (message_type == "ident") {
                        // New unique client file identifier from server.
                        unsigned sessionIdent = 0;
                        uint_fast64_t fileIdent = 0;
                        char sp1, sp2;
                        parser >> sp1 >> sessionIdent >> sp2 >> fileIdent;
                        bool good = parser && parser.eof() && sp1 == ' ' && sp2 == ' ';
                        if (!good) {
                            NSLog(@"RealmSync: Connection[%lu]: Bad 'ident' message "
                                  "from server", _ident);
                            // FIXME: Report the error, close the connection,
                            // and try to reconnect later
                            return;
                        }
                        NSNumber *sessionIdent2 = [NSNumber numberWithUnsignedInteger:sessionIdent];
                        [self handleIdentMessageWithSessionIdent:sessionIdent2 fileIdent:fileIdent];
                    }
                    else {
                        NSLog(@"RealmSync: Connection[%lu]: Bad message from server", _ident);
                        // FIXME: Report the error, close the connection, and
                        // try to reconnect later
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
                    size_t avail = min(sourceAvail, destAvail);
                    const char *i = inputBegin + avail;
                    _messageBodyCurr = copy(inputBegin, i, _messageBodyCurr);
                    inputBegin = i;
                    if (_messageBodyCurr != messageBodyEnd) {
                        TIGHTDB_ASSERT(inputBegin == inputEnd);
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
            TIGHTDB_ASSERT(_currentOutputChunk);
            const uint8_t *buffer = reinterpret_cast<const uint8_t *>(_currentOutputBegin);
            NSUInteger length = _currentOutputEnd - _currentOutputBegin;
            NSInteger n = [_outputStream write:buffer maxLength:length];
            if (n < 0) {
                NSLog(@"RealmSync: Connection[%lu]: Error writing to socket: %@",
                      _ident, _outputStream.streamError);
                // FIXME: Report the error, close the connection, and try to
                // reconnect later
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
            // FIXME: Report the error, and try to reconnect later
            return;
        }
        case NSStreamEventErrorOccurred: {
            if (stream != _inputStream && stream != _outputStream)
                return;
            NSLog(@"RealmSync: Connection[%lu]: Socket error: %@",
                  _ident, _outputStream.streamError);
            // FIXME: Report the error, close the connection, and try to reconnect later
            return;
        }
    }
}


- (void)handleIdentMessageWithSessionIdent:(NSNumber *)sessionIdent
                                 fileIdent:(uint_fast64_t)fileIdent {
    typedef unsigned long long ulonglong;
    NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Received: Identify client file by %llu",
          _ident, sessionIdent, ulonglong(fileIdent));

    RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
    if (!session)
        return; // This session no longer exists

    [session handleIdentMessageWithFileIdent:fileIdent];
}


- (void)handleChangesetMessageWithSessionIdent:(NSNumber *)sessionIdent
                                 serverVersion:(Replication::version_type)serverVersion
                                 clientVersion:(Replication::version_type)clientVersion
                               originTimestamp:(uint_fast64_t)originTimestamp
                               originFileIdent:(uint_fast64_t)originFileIdent {
    if (s_syncLogEverything) {
        typedef unsigned long long ulonglong;
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Received: Changeset %llu -> %llu "
              "of size %lu with origin timestamp %llu and origin client file identifier %llu "
              "(last integrated client version is %llu)", _ident, sessionIdent,
              ulonglong(serverVersion-1), ulonglong(serverVersion), _messageBodyBuffer.length,
              ulonglong(originTimestamp), ulonglong(originFileIdent), ulonglong(clientVersion));
    }

    RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
    if (!session)
        return; // This session no longer exists

    NSData *data = _messageBodyBuffer;
    _messageBodyBuffer = nil;

    [session handleChangesetMessageWithServerVersion:serverVersion
                                       clientVersion:clientVersion
                                     originTimestamp:originTimestamp
                                     originFileIdent:originFileIdent
                                                data:data];
}


- (void)handleAcceptMessageWithSessionIdent:(NSNumber *)sessionIdent
                              serverVersion:(Replication::version_type)serverVersion
                              clientVersion:(Replication::version_type)clientVersion {
    if (s_syncLogEverything) {
        typedef unsigned long long ulonglong;
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Received: Accept changeset %llu -> %llu "
              " (producing server version %llu)", _ident, sessionIdent,
              ulonglong(clientVersion-1), ulonglong(clientVersion), ulonglong(serverVersion));
    }

    RLMSyncSession *session = [_sessions objectForKey:sessionIdent];
    if (!session)
        return; // This session no longer exists

    [session handleAcceptMessageWithServerVersion:serverVersion clientVersion:clientVersion];
}

@end


@implementation RLMSyncSession {
    unique_ptr<SharedGroup> _sharedGroup;
    unique_ptr<Replication> _history;

    unique_ptr<SharedGroup> _backgroundSharedGroup; // For background thread
    unique_ptr<Replication> _backgroundHistory;     // For background thread

    Replication::version_type _latestVersionAvailable;
    Replication::version_type _latestVersionUploaded;
    Replication::version_type _syncProgressServerVersion;
    Replication::version_type _syncProgressClientVersion;
    Replication::version_type _serverVersionThreshold;
    BOOL _uploadInProgress;

    NSOperationQueue *_backgroundOperationQueue;
}


- (instancetype)initWithConnection:(RLMServerConnection *)connection
                        clientPath:(NSString *)clientPath
                        serverPath:(NSString *)serverPath {
    self = [super init];
    if (self) {
        _connection = connection;
        _fileIdent = 0; // Zero means unassigned
        _clientPath = clientPath;
        _serverPath = serverPath;
        _sessionIdent = [NSNumber numberWithUnsignedInteger:[connection newSessionIdent]];

        bool serverSynchronizationMode = true;
        SharedGroup::DurabilityLevel durability = SharedGroup::durability_Full;
        _history.reset(makeWriteLogCollector(clientPath.UTF8String,
                                             serverSynchronizationMode));
        _sharedGroup = make_unique<SharedGroup>(*_history, durability);
        _backgroundHistory.reset(makeWriteLogCollector(clientPath.UTF8String,
                                                       serverSynchronizationMode));
        _backgroundSharedGroup =
            make_unique<SharedGroup>(*_backgroundHistory, durability);

        _uploadInProgress = NO;

        _backgroundOperationQueue = [[NSOperationQueue alloc] init];
        _backgroundOperationQueue.name = @"io.realm.sync";
        _backgroundOperationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}


- (void)mainThreadInit {
    // Called by main thread
    uint_fast64_t fileIdent;
    _history->get_sync_info(fileIdent, _syncProgressServerVersion, _syncProgressClientVersion);
    _fileIdent = fileIdent;

    TIGHTDB_ASSERT(_syncProgressClientVersion >= 1);

    _latestVersionAvailable = LangBindHelper::get_current_version(*_sharedGroup);
    TIGHTDB_ASSERT(_latestVersionAvailable >= 1);

    // Due to the nature of the protocol, it is possible that the server sends a
    // changeset that was already integrated locally. To be able to detect this
    // situation, we need to know the latest server version that is already
    // integrated, so that we can skip those changesets. We have
    // `_syncProgressServerVersionSince`, but it is not guaranteed to be
    // completely up to date with what is actually in the history. For that
    // reason, we have to manually search a portion of the history.
    //
    // FIXME: Consider whether this can be done in the same way, and at the same
    // time as latest_local_time_seen and latest_remote_time_seen are managed
    // inside the CommitLogs class.
    _serverVersionThreshold = _syncProgressServerVersion;
    {
        Replication::CommitLogEntry historyEntry;
        Replication::version_type version = _latestVersionAvailable;
        while (version > _syncProgressClientVersion) {
            _history->get_commit_entries(version-1, version, &historyEntry);
            BOOL isForeign = historyEntry.peer_id != 0;
            if (isForeign) {
                _serverVersionThreshold = version;
                break;
            }
            --version;
        }
    }

/*
    NSLog(@"_latestVersionAvailable = %llu", (unsigned long long)(_latestVersionAvailable));
    NSLog(@"_latestVersionUploaded = %llu", (unsigned long long)(_latestVersionUploaded));
    NSLog(@"_syncProgressServerVersion = %llu", (unsigned long long)(_syncProgressServerVersion));
    NSLog(@"_syncProgressClientVersion = %llu", (unsigned long long)(_syncProgressClientVersion));
    NSLog(@"_serverVersionThreshold = %llu", (unsigned long long)(_serverVersionThreshold));
*/

    [_connection mainThreadInit];
    [_connection addSession:self];
}


- (void)refreshLatestVersionAvailable {
    _latestVersionAvailable = LangBindHelper::get_current_version(*_sharedGroup);
    if (_connection.isOpen && _fileIdent != 0)
        [self resumeUpload];
}


- (void)connectionIsOpen {
    if (_fileIdent == 0) {
        [_connection sendIdentMessageWithSessionIdent:_sessionIdent
                                           serverPath:_serverPath];
        return;
    }

    _latestVersionUploaded = _syncProgressClientVersion;
    if (_latestVersionUploaded > _latestVersionAvailable) // Transiently possible (FIXME: Or is it?)
        _latestVersionUploaded = _latestVersionAvailable;
    [_connection sendBindMessageWithSessionIdent:_sessionIdent
                                       fileIdent:_fileIdent
                                   serverVersion:_syncProgressServerVersion
                                   clientVersion:_syncProgressClientVersion
                                      serverPath:_serverPath
                                      clientPath:_clientPath];
    [self resumeUpload];
}


- (void)resumeUpload {
    TIGHTDB_ASSERT(_connection.isOpen && _fileIdent != 0);
    if (_uploadInProgress)
        return;
    _uploadInProgress = YES;

    // Fetch and copy the next changeset, and produce an output message from it.
    // Set the completionHandler to a block that calls resumeUpload.
    Replication::version_type uploadVersion;
    Replication::CommitLogEntry historyEntry;
    for (;;) {
        TIGHTDB_ASSERT(_latestVersionUploaded <= _latestVersionAvailable);
        if (_latestVersionUploaded == _latestVersionAvailable) {
            _uploadInProgress = NO;
            return;
        }
        uploadVersion = _latestVersionUploaded + 1;
        _history->get_commit_entries(uploadVersion-1, uploadVersion, &historyEntry);
        // Skip changesets that were downloaded from the server
        BOOL isForeign = historyEntry.peer_id != 0;
        if (!isForeign)
            break;
        _latestVersionUploaded = uploadVersion;
    }
    typedef unsigned long long ulonglong;
    // `serverVersion` is the last server version that has been integrated into
    // `uploadVersion`.
    ulonglong serverVersion = historyEntry.peer_version;
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.body = [NSData dataWithBytes:historyEntry.log_data.data()
                              length:historyEntry.log_data.size()]; // Full copy
    msg.head = [NSString stringWithFormat:@"changeset %@ %llu %llu %llu %lu\n", _sessionIdent,
                         ulonglong(uploadVersion), ulonglong(serverVersion),
                         ulonglong(historyEntry.timestamp), msg.body.length];
    if (s_syncLogEverything) {
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Sending: Changeset %llu -> %llu "
              "of size %lu with timestamp %llu (last integrated server version is %llu)",
              _connection.ident, _sessionIdent, ulonglong(uploadVersion-1),
              ulonglong(uploadVersion), msg.body.length, ulonglong(historyEntry.timestamp),
              serverVersion);
    }
    __weak RLMSyncSession *weakSelf = self;
    [msg setCompletionHandler:^{
            [weakSelf uplaodCompletedWithVersion:uploadVersion];
        }];
    [_connection enqueueOutputMessage:msg];
}


- (void)uplaodCompletedWithVersion:(Replication::version_type)version {
    TIGHTDB_ASSERT(version <= _latestVersionUploaded+1);
    _uploadInProgress = NO;
    if (_latestVersionUploaded < version)
        _latestVersionUploaded = version;
    if (_connection.isOpen)
        [self resumeUpload];
}


- (void)handleIdentMessageWithFileIdent:(uint_fast64_t)fileIdent {
    _history->set_client_file_ident(fileIdent); // Save in persistent storage
    _fileIdent = fileIdent;
    if (_connection.isOpen)
        [self connectionIsOpen];
}


- (void)handleChangesetMessageWithServerVersion:(Replication::version_type)serverVersion
                                  clientVersion:(Replication::version_type)clientVersion
                                originTimestamp:(uint_fast64_t)originTimestamp
                                originFileIdent:(uint_fast64_t)originFileIdent
                                           data:(NSData *)data {
    // We cannot save the synchronization progress marker (`serverVersion`,
    // `clientVersion`) to persistent storage until the changeset is actually
    // integrated locally, but that means it will be delayed by two context
    // switches, i.e., first by a switch to the background thread, and then by a
    // switch back to the main thread, and in each of these switches there is a
    // risk of termination of the flow of this information due to a severed weak
    // reference, which presumably would be due to the termination of the
    // synchronization session, but not necessarily in connection with the
    // termination of the application.
    //
    // Additionally, we want to be able to make a proper monotony check on
    // `serverVersion` and `clientVersion` before having the background thread
    // attempting to apply the changeset, and to do that, we must both check and
    // update `_syncProgressServerVersion` and `_syncProgressClientVersion`
    // right here in the main thread.
    //
    // Note: The server version must increase, since it is the number of a new
    // server version. The client version, however, can only be increased by an
    // 'accept' message, so it must remain unchanged here.
    bool good_versions = serverVersion > _syncProgressServerVersion &&
        clientVersion == _syncProgressClientVersion;
    if (!good_versions) {
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: ERROR: Bad server or client version "
              "in 'changeset' message", _connection.ident, _sessionIdent);
        [_connection close];
        return;

    }
    _syncProgressServerVersion = serverVersion;
    _syncProgressClientVersion = clientVersion;

    // Skip changesets that were already integrated during an earlier session,
    // but still attempt to save a new synchronization progress marker to
    // persistent storage.
    if (clientVersion <= _serverVersionThreshold) {
        if (s_syncLogEverything) {
            NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Ignoring previously integrated "
                  "changeset", _connection.ident, _sessionIdent);
        }
        [self addBackgroundTaskWithServerVersion:serverVersion
                                   clientVersion:clientVersion
                                 originTimestamp:0
                                 originFileIdent:0
                                            data:nil];
        return;
    }

    // FIXME: Consider whether we should attempt to apply small changsesets
    // immediately on the main thread (right here) if auto-refresh is enabled,
    // `_backgroundOperationQueue` is empty, and a try-lock on the
    // write-transaction mutex succeeds. This might be an effective way of
    // reducing latency due to context switches.

    [self addBackgroundTaskWithServerVersion:serverVersion
                               clientVersion:clientVersion
                             originTimestamp:originTimestamp
                             originFileIdent:originFileIdent
                                        data:data];
}


- (void)handleAcceptMessageWithServerVersion:(Replication::version_type)serverVersion
                               clientVersion:(Replication::version_type)clientVersion {
    // As with 'changeset' messages, we need to update the synchronization
    // progress marker.
    //
    // FIXME: Properly explain the three roles of the synchronization progress
    // marker (syncronization restart point, history upload window specifier,
    // and history merge window specifier), and the intricate interplay between
    // them.
    //
    // Note: The server version must increase, since it is the number of a new
    // server version. The client version must also increase, because it
    // specifies the last integrated client version, and an 'accept' message
    // implies that a new client version was integrated.
    bool good_versions = serverVersion > _syncProgressServerVersion &&
        clientVersion > _syncProgressClientVersion &&
        clientVersion <= _latestVersionUploaded;
    if (!good_versions) {
        NSLog(@"RealmSync: Connection[%lu]: Session[%@]: ERROR: Bad server or client version "
              "in 'accept' message", _connection.ident, _sessionIdent);
        [_connection close];
        return;

    }
    _syncProgressServerVersion = serverVersion;
    _syncProgressClientVersion = clientVersion;

    // The order in which updated synchronization progress markers are saved to
    // persistent storage must be the same order in with the are received from
    // the server either via a 'changeset' message or an 'accept' message.
        [self addBackgroundTaskWithServerVersion:serverVersion
                                   clientVersion:clientVersion
                                 originTimestamp:0
                                 originFileIdent:0
                                            data:nil];
}


- (void)addBackgroundTaskWithServerVersion:(Replication::version_type)serverVersion
                             clientVersion:(Replication::version_type)clientVersion
                           originTimestamp:(uint_fast64_t)originTimestamp
                           originFileIdent:(uint_fast64_t)originFileIdent
                                      data:(NSData *)data {
    __weak RLMSyncSession *weakSelf = self;
    [_backgroundOperationQueue addOperationWithBlock:^{
            [weakSelf backgroundTaskWithServerVersion:serverVersion
                                        clientVersion:clientVersion
                                      originTimestamp:originTimestamp
                                      originFileIdent:originFileIdent
                                                 data:data];
        }];
}


- (void)backgroundTaskWithServerVersion:(Replication::version_type)serverVersion
                          clientVersion:(Replication::version_type)clientVersion
                        originTimestamp:(uint_fast64_t)originTimestamp
                        originFileIdent:(uint_fast64_t)originFileIdent
                                   data:(NSData *)data {
    if (data)
        [self backgroundApplyChangesetWithServerVersion:serverVersion
                                          clientVersion:clientVersion
                                        originTimestamp:originTimestamp
                                        originFileIdent:originFileIdent
                                                   data:data];

    __weak RLMSyncSession *weakSelf = self;
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [mainQueue addOperationWithBlock:^{
            [weakSelf updateSyncProgressWithServerVersion:serverVersion
                                            clientVersion:clientVersion];
        }];
}


- (void)backgroundApplyChangesetWithServerVersion:(Replication::version_type)serverVersion
                                    clientVersion:(Replication::version_type)clientVersion
                                  originTimestamp:(uint_fast64_t)originTimestamp
                                  originFileIdent:(uint_fast64_t)originFileIdent
                                             data:(NSData *)data {
    typedef unsigned long long ulonglong;
    Replication::version_type baseVersion = clientVersion;
    Replication::version_type newVersion;
    const char *data2 = static_cast<const char *>(data.bytes);
    size_t size = data.length;
    BinaryData changeset(data2, size);
    ostream *applyLog = 0;
    BOOL conflict;
    try {
        TIGHTDB_ASSERT(baseVersion >= 1);
        Replication &history = *_backgroundHistory;
        newVersion = history.apply_foreign_changeset(*_backgroundSharedGroup, baseVersion,
                                                     changeset, originTimestamp, originFileIdent,
                                                     serverVersion, applyLog);
        conflict = (newVersion == 0);
    }
    catch (Replication::BadTransactLog&) {
        NSString *message = [NSString stringWithFormat:@"Application of server changeset "
                                      "%llu -> %llu failed", ulonglong(serverVersion-1),
                                      ulonglong(serverVersion)];
        @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil];
    }

    if (!conflict) {
        if (s_syncLogEverything) {
            NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Server changeset (%llu -> %llu) "
                  "integrated (producing client version %llu)", _connection.ident, _sessionIdent,
                  ulonglong(serverVersion-1), ulonglong(serverVersion), ulonglong(newVersion));
        }
        [RLMRealm notifyRealmsAtPath:_clientPath exceptRealm:nil];
        return;
    }

/*
    // If the last changeset is local, or if the history is empty,
    // require that the last integragted client version of the
    // incoming changeset is the current client version, i.e., the
    // client version produced by the last changeset in the local
    // history.
    BOOL lastChangesetIsFromServer = NO;
    if (current_server_version > first_server_version) {
        Replication::CommitLogEntry lastHistoryEntry;
        _backgroundHistory->get_commit_entries(baseVersion, baseVersion+1, &firstHistoryEntry);
        lastChangesetIsFromServer = (lastHistoryEntry.peer_id != 0);
    }
*/

    // WARNING: Strictly speaking, the following is not the correct resolution
    // of the conflict between two identical initial changesets, but it is done
    // as a temporary workaround to allow the current version of this binding to
    // carry out an initial schema creating transaction without getting into an
    // immediate unrecoverable conflict. It does not work in general as even the
    // initial changeset is allowed to contain elements that are additive rather
    // than idempotent.
    bool conflictOnFirstChangeset = baseVersion == 1;
    if (conflictOnFirstChangeset) {
        Replication::CommitLogEntry firstHistoryEntry;
        _backgroundHistory->get_commit_entries(baseVersion, baseVersion+1, &firstHistoryEntry);
        BOOL isForeign = (firstHistoryEntry.peer_id != 0);
        BOOL identicalSchemaCreatingTransactions = !isForeign &&
            firstHistoryEntry.log_data == changeset;
        if (identicalSchemaCreatingTransactions) {
            BinaryData emptyChangeset;
            Replication &history = *_backgroundHistory;
            newVersion = history.apply_foreign_changeset(*_backgroundSharedGroup, 0,
                                                         emptyChangeset, originTimestamp,
                                                         originFileIdent, serverVersion,
                                                         applyLog);
            TIGHTDB_ASSERT(newVersion != 0);
            NSLog(@"RealmSync: Connection[%lu]: Session[%@]: Conflict on identical initial "
                  "schema-creating transactions resolved (impropperly) (producing client "
                  "version %llu)", _connection.ident, _sessionIdent, ulonglong(newVersion));
            return;
        }
    }

    NSString *message =
        [NSString stringWithFormat:@"RealmSync: Connection[%lu]: Session[%@]: Conflict between "
                  "client version %llu and server version %llu", _connection.ident, _sessionIdent,
                  ulonglong(baseVersion+1), ulonglong(serverVersion)];
    @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil];
}


- (void)updateSyncProgressWithServerVersion:(Replication::version_type)serverVersion
                              clientVersion:(Replication::version_type)clientVersion {
    _history->set_sync_progress(serverVersion, clientVersion);
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


NSString * const c_defaultRealmFileName = @"default.realm";

@implementation RLMRealm {
    // Used for read-write realms
    NSThread *_thread;
    NSMapTable *_notificationHandlers;

    std::unique_ptr<Replication> _replication;
    std::unique_ptr<SharedGroup> _sharedGroup;

    // Used for read-only realms
    std::unique_ptr<Group> _readGroup;

    // Used for both
    Group *_group;
    BOOL _readOnly;
    BOOL _inMemory;

    NSURL *_serverBaseURL;
    RLMSyncSession *_syncSession;
}

+ (BOOL)isCoreDebug {
    return tightdb::Version::has_feature(tightdb::feature_Debug);
}

+ (void)initialize {
    static bool initialized;
    if (initialized) {
        return;
    }
    initialized = true;

    // set up global realm cache
    RLMCheckForUpdates();

    // initilize realm cache
    clearRealmCache();
}

- (instancetype)initWithPath:(NSString *)path key:(NSData *)key readOnly:(BOOL)readonly inMemory:(BOOL)inMemory error:(NSError **)error serverBaseURL:(NSURL *)serverBaseURL {
    if (key && [key length] != 64) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Encryption key must be exactly 64 bytes long"
                                     userInfo:nil];
    }

    if (key && isDebuggerAttached()) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Cannot open an encrypted Realm with a debugger attached to the process"
                                     userInfo:nil];
    }

    self = [super init];
    if (self) {
        _path = path;
        _thread = [NSThread currentThread];
        _threadID = pthread_mach_thread_np(pthread_self());
        _notificationHandlers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory];
        _readOnly = readonly;
        _inMemory = inMemory;
        _autorefresh = YES;
        _serverBaseURL = serverBaseURL;

        try {
            if (readonly) {
                _readGroup = make_unique<Group>(path.UTF8String, static_cast<const char *>(key.bytes));
                _group = _readGroup.get();
            }
            else {
                // FIXME: The SharedGroup constructor, when called below, will
                // throw a C++ exception if server_synchronization_mode is
                // inconsistent with the accessed Realm file. This exception
                // probably has to be transmuted to an NSError.
                bool server_synchronization_mode = bool(serverBaseURL);
                _replication.reset(tightdb::makeWriteLogCollector(path.UTF8String, server_synchronization_mode,
                                                                  static_cast<const char *>(key.bytes)));
                SharedGroup::DurabilityLevel durability = inMemory ? SharedGroup::durability_MemOnly :
                                                                     SharedGroup::durability_Full;
                _sharedGroup = make_unique<SharedGroup>(*_replication, durability,
                                                        static_cast<const char *>(key.bytes));
            }
        }
        catch (File::PermissionDenied &ex) {
            NSString *mode = readonly ? @"read" : @"read-write";
            NSString *additionalMessage = [NSString stringWithFormat:@"Unable to open a realm at path '%@'. Please use a path where your app has %@ permissions.", path, mode];
            NSString *newMessage = [NSString stringWithFormat:@"%s\n%@", ex.what(), additionalMessage];
            ex = File::PermissionDenied(newMessage.UTF8String);
            *error = make_realm_error(RLMErrorFilePermissionDenied, ex);
        }
        catch (File::Exists &ex) {
            *error = make_realm_error(RLMErrorFileExists, ex);
        }
        catch (File::AccessError &ex) {
            *error = make_realm_error(RLMErrorFileAccessError, ex);
        }
        catch (exception &ex) {
            *error = make_realm_error(RLMErrorFail, ex);
        }
    }
    return self;
}

- (tightdb::Group *)getOrCreateGroup {
    if (!_group) {
        _group = &const_cast<Group&>(_sharedGroup->begin_read());
    }
    return _group;
}

+ (NSString *)defaultRealmPath
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!s_defaultRealmPath) {
            s_defaultRealmPath = [RLMRealm writeablePathForFile:c_defaultRealmFileName];
        }
    });
    return s_defaultRealmPath;
}

+ (void)setDefaultRealmPath:(NSString *)defaultRealmPath {
    s_defaultRealmPath = defaultRealmPath;
}

+ (NSString *)writeablePathForFile:(NSString*)fileName
{
#if TARGET_OS_IPHONE
    // On iOS the Documents directory isn't user-visible, so put files there
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#else
    // On OS X it is, so put files in Application Support. If we aren't running
    // in a sandbox, put it in a subdirectory based on the bundle identifier
    // to avoid accidentally sharing files between applications
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    if (![[NSProcessInfo processInfo] environment][@"APP_SANDBOX_CONTAINER_ID"]) {
        NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
        if ([identifier length] == 0) {
            identifier = [[[NSBundle mainBundle] executablePath] lastPathComponent];
        }
        path = [path stringByAppendingPathComponent:identifier];

        // create directory
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
#endif
    return [path stringByAppendingPathComponent:fileName];
}

+ (instancetype)defaultRealm
{
    return [RLMRealm realmWithPath:[RLMRealm defaultRealmPath] readOnly:NO error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
{
    return [self realmWithPath:path readOnly:NO error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                        error:(NSError **)outError
{
    return [self realmWithPath:path key:nil readOnly:readonly inMemory:NO dynamic:NO schema:nil error:outError];
}

+ (instancetype)inMemoryRealmWithIdentifier:(NSString *)identifier {
    return [self realmWithPath:[RLMRealm writeablePathForFile:identifier] key:nil
                      readOnly:NO inMemory:YES dynamic:NO schema:nil error:nil];
}

+ (instancetype)encryptedRealmWithPath:(NSString *)path
                                   key:(NSData *)key
                              readOnly:(BOOL)readonly
                                 error:(NSError **)error
{
    if (!key) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Encryption key must not be nil" userInfo:nil];
    }

    return [self realmWithPath:path key:key readOnly:readonly inMemory:NO dynamic:NO schema:nil error:error];
}


+ (instancetype)realmWithPath:(NSString *)path
                          key:(NSData *)key
                     readOnly:(BOOL)readonly
                     inMemory:(BOOL)inMemory
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError
{
    if (!path || path.length == 0) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Path is not valid"
                                     userInfo:@{@"path":(path ?: @"nil")}];
    }

    if (![NSRunLoop currentRunLoop]) {
        @throw [NSException exceptionWithName:@"realm:runloop_exception"
                                       reason:[NSString stringWithFormat:@"%@ \
                                               can only be called from a thread with a runloop.",
                                               NSStringFromSelector(_cmd)] userInfo:nil];
    }

    // try to reuse existing realm first
    __autoreleasing RLMRealm *realm = nil;
    if (!dynamic && !customSchema) {
        realm = cachedRealm(path);
    }

    if (realm) {
        // if already opened with different read permissions then throw
        if (realm->_readOnly != readonly) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Realm at path already opened with different read permissions"
                                         userInfo:@{@"path":realm.path}];
        }
        if (realm->_inMemory != inMemory) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Realm at path already opened with different inMemory settings"
                                         userInfo:@{@"path":realm.path}];
        }
        return realm;
    }

    if (!key) {
        @synchronized (s_keysPerPath) {
            key = s_keysPerPath[path];
        }
    }

    NSURL *serverBaseURL;
    @synchronized (s_serverBaseURLS) {
        serverBaseURL = s_serverBaseURLS[path];
    }

    NSError *error = nil;
    realm = [[RLMRealm alloc] initWithPath:path key:key readOnly:readonly inMemory:inMemory error:&error serverBaseURL:serverBaseURL];
    realm->_dynamic = dynamic;

    if (error) {
        if (outError) {
            *outError = error;
            return nil;
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[error localizedDescription]
                                         userInfo:nil];
        }
    }

    if (!realm) {
        return nil;
    }

    // we need to protect the realm cache and accessors cache
    @synchronized(s_realmsPerPath) {
        // create tables, set schema, and create accessors when needed
        if (customSchema) {
            if (!dynamic) {
                @throw [NSException exceptionWithName:@"RLMException" reason:@"Custom schema only supported when using dynamic Realms" userInfo:nil];
            }
            createTablesInTransaction(realm, customSchema);
        }
        else if (dynamic) {
            createTablesInTransaction(realm, [RLMSchema dynamicSchemaFromRealm:realm]);
        }
        else if (readonly) {
            if (RLMRealmSchemaVersion(realm) == RLMNotVersioned) {
                @throw [NSException exceptionWithName:@"RLMException"
                                               reason:@"Cannot open an uninitialized realm in read-only mode"
                                             userInfo:nil];
            }
            RLMRealmSetSchema(realm, [RLMSchema sharedSchema], true);
            RLMRealmCreateAccessors(realm.schema);

            cacheRealm(realm, path);
        }
        else {
            // check cache for existing cached realms with the same path
            NSArray *realms = realmsAtPath(path);
            if (realms.count) {
                RLMRealm *sourceRealm = realms[0];

                // if we have a cached realm on another thread, copy without a transaction
                RLMRealmSetSchema(realm, [sourceRealm schema], false);

                // Ensured by the SharedGroup constructor.
                TIGHTDB_ASSERT(bool(sourceRealm->_serverBaseURL) == bool(realm->_serverBaseURL));

                if (realm->_serverBaseURL) {
                    if (![realm->_serverBaseURL isEqual:sourceRealm->_serverBaseURL]) {
                        @throw [NSException exceptionWithName:@"RLMException"
                                                       reason:@"Server synchronization URL mismatch"
                                                     userInfo:nil];
                    }
                    realm->_syncSession = sourceRealm->_syncSession;
                }
            }
            else {
                RLMSyncSession *session = 0;
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
                session = [s_syncSessions objectForKey:realm.path];
                if (!session) {
                    if (serverBaseURL) {
                        NSString *hostKey = serverBaseURL.host;
                        if (serverBaseURL.port) {
                            hostKey = [NSString stringWithFormat:@"%@:%@", serverBaseURL.host, serverBaseURL.port];
                        }
                        RLMServerConnection *conn = [s_serverConnections objectForKey:hostKey];
                        if (!conn) {
                            unsigned long serverConnectionIdent = ++s_lastServerConnectionIdent;
                            conn = [[RLMServerConnection alloc] initWithIdent:serverConnectionIdent
                                                                      address:serverBaseURL.host
                                                                         port:serverBaseURL.port];
                            [s_serverConnections setObject:conn forKey:hostKey];
                        }
                        session = [[RLMSyncSession alloc] initWithConnection:conn
                                                                  clientPath:realm.path
                                                                  serverPath:serverBaseURL.path];
                        [s_syncSessions setObject:session forKey:realm.path];
                        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
                        __weak RLMSyncSession *weakSession = session;
                        [mainQueue addOperationWithBlock:^{
                                [weakSession mainThreadInit];
                            }];
                    }
                }
                realm->_syncSession = session;

                // if we are the first realm at this path, set/align schema or perform migration if needed
                NSUInteger schemaVersion = RLMRealmSchemaVersion(realm);
                if (s_currentSchemaVersion == schemaVersion || schemaVersion == RLMNotVersioned) {
                    createTablesInTransaction(realm, [RLMSchema sharedSchema]);
                }
                else {
                    [RLMRealm migrateRealm:realm key:key];
                }

                RLMRealmCreateAccessors(realm.schema);
            }

            // initializing the schema started a read transaction, so end it
            [realm invalidate];

            // cache only realms using a shared schema
            cacheRealm(realm, path);
        }
    }

    return realm;
}

+ (void)setEncryptionKey:(NSData *)key forRealmsAtPath:(NSString *)path {
    if (!key) {
        @synchronized (s_keysPerPath) {
            [s_keysPerPath removeObjectForKey:path];
            return;
        }
    }

    if ([key length] != 64) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Encryption key must be exactly 64 bytes"
                                     userInfo:nil];
    }

    @synchronized (s_keysPerPath) {
        s_keysPerPath[path] = key;
    }
}

+ (void)resetRealmState {
    s_currentSchemaVersion = 0;
    s_migrationBlock = NULL;
    clearRealmCache();
}

static void CheckReadWrite(RLMRealm *realm, NSString *msg=@"Cannot write to a read-only Realm") {
    if (realm->_readOnly) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:msg
                                     userInfo:nil];
    }
}

- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Read-only Realms do not change and do not have change notifications");
    if (!block) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"The notification block should not be nil" userInfo:nil];
    }

    RLMNotificationToken *token = [[RLMNotificationToken alloc] init];
    token.realm = self;
    token.block = block;
    [_notificationHandlers setObject:token forKey:token];
    return token;
}

- (void)removeNotification:(RLMNotificationToken *)token {
    RLMCheckThread(self);
    if (token) {
        [_notificationHandlers removeObjectForKey:token];
        token.realm = nil;
        token.block = nil;
    }
}

- (void)sendNotifications:(NSString *)notification {
    NSAssert(!_readOnly, @"Read-only realms do not have notifications");

    // call this realms notification blocks
    for (RLMNotificationToken *token in [_notificationHandlers copy]) {
        if (token.block) {
            token.block(notification, self);
        }
    }
}

- (void)beginWriteTransaction {
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (!self.inWriteTransaction) {
        try {
            // if the upgrade to write will move the transaction forward,
            // announce the change after promoting
            bool announce = _sharedGroup->has_changed();

            // begin the read transaction if needed
            [self getOrCreateGroup];

            LangBindHelper::promote_to_write(*_sharedGroup);

            if (announce) {
                [self sendNotifications:RLMRealmDidChangeNotification];
            }

            // update state and make all objects in this realm writable
            _inWriteTransaction = YES;
        }
        catch (std::exception& ex) {
            // File access errors are treated as exceptions here since they should not occur after the shared
            // group has already been successfully opened on the file and memory mapped. The shared group constructor handles
            // the excepted error related to file access.
            throw_objc_exception(ex);
        }
    } else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"The Realm is already in a writetransaction" userInfo:nil];
    }
}

- (void)commitWriteTransaction {
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (self.inWriteTransaction) {
        try {
            LangBindHelper::commit_and_continue_as_read(*_sharedGroup);

            // update state and make all objects in this realm read-only
            _inWriteTransaction = NO;

            // notify other realm instances of changes
            [RLMRealm notifyRealmsAtPath:_path exceptRealm:self];

            // send local notification
            [self sendNotifications:RLMRealmDidChangeNotification];

            NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
            __weak RLMSyncSession *weakSession = _syncSession;
            [mainQueue addOperationWithBlock:^{
                    [weakSession refreshLatestVersionAvailable];
                }];
        }
        catch (std::exception& ex) {
            throw_objc_exception(ex);
        }
    } else {
       @throw [NSException exceptionWithName:@"RLMException" reason:@"Can't commit a non-existing write transaction" userInfo:nil];
    }
}

+ (void)notifyRealmsAtPath:(NSString *)path exceptRealm:(RLMRealm *)exceptRealm {
    NSArray *realms = realmsAtPath(path);
    for (RLMRealm *realm in realms) {
        // FIXME: Why is this not just a pointer comparison?
        if (exceptRealm && [realm isEqual:exceptRealm])
            continue;
        RLMWeakNotifier *notifier = [[RLMWeakNotifier alloc] initWithRealm:realm];
        [notifier performSelector:@selector(notify)
                         onThread:realm->_thread withObject:nil waitUntilDone:NO];
    }
}

- (void)transactionWithBlock:(void(^)(void))block {
    [self beginWriteTransaction];
    block();
    if (_inWriteTransaction) {
        [self commitWriteTransaction];
    }
}

- (void)cancelWriteTransaction {
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (self.inWriteTransaction) {
        try {
            LangBindHelper::rollback_and_continue_as_read(*_sharedGroup);
            _inWriteTransaction = NO;
        }
        catch (std::exception& ex) {
            throw_objc_exception(ex);
        }
    } else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Can't cancel a non-existing write transaction" userInfo:nil];
    }
}

- (void)invalidate {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Cannot invalidate a read-only realm");

    if (_inWriteTransaction) {
        NSLog(@"WARNING: An RLMRealm instance was invalidated during a write "
              "transaction and all pending changes have been rolled back.");
        [self cancelWriteTransaction];
    }
    if (!_group) {
        // Nothing to do if the read transaction hasn't been begun
        return;
    }

    _sharedGroup->end_read();
    _group = nullptr;
    for (RLMObjectSchema *objectSchema in _schema.objectSchema) {
        objectSchema.table = nullptr;
    }
}

- (void)dealloc {
    if (_inWriteTransaction) {
        [self cancelWriteTransaction];
        NSLog(@"WARNING: An RLMRealm instance was deallocated during a write transaction and all "
              "pending changes have been rolled back. Make sure to retain a reference to the "
              "RLMRealm for the duration of the write transaction.");
    }
}

- (void)handleExternalCommit {
    RLMCheckThread(self);
    NSAssert(!_readOnly, @"Read-only realms do not have notifications");
    try {
        if (_sharedGroup->has_changed()) { // Throws
            if (_autorefresh) {
                if (_group) {
                    LangBindHelper::advance_read(*_sharedGroup);
                }
                [self sendNotifications:RLMRealmDidChangeNotification];
            }
            else {
                [self sendNotifications:RLMRealmRefreshRequiredNotification];
            }
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (BOOL)refresh {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Cannot refresh a read-only realm (external modifications to read only realms are not supported)");

    // can't be any new changes if we're in a write transaction
    if (self.inWriteTransaction) {
        return NO;
    }

    try {
        // advance transaction if database has changed
        if (_sharedGroup->has_changed()) { // Throws
            if (_group) {
                LangBindHelper::advance_read(*_sharedGroup);
            }
            else {
                // Create the read transaction
                [self getOrCreateGroup];
            }
            [self sendNotifications:RLMRealmDidChangeNotification];
            return YES;
        }
        return NO;
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (void)addObject:(RLMObject *)object {
    RLMAddObjectToRealm(object, self, RLMCreationOptionsNone);
}

- (void)addObjects:(id<NSFastEnumeration>)array {
    for (RLMObject *obj in array) {
        if (![obj isKindOfClass:[RLMObject class]]) {
            NSString *msg = [NSString stringWithFormat:@"Cannot insert objects of type %@ with addObjects:. Only RLMObjects are supported.", NSStringFromClass(obj.class)];
            @throw [NSException exceptionWithName:@"RLMException" reason:msg userInfo:nil];
        }
        [self addObject:obj];
    }
}

- (void)addOrUpdateObject:(RLMObject *)object {
    // verify primary key
    if (!object.objectSchema.primaryKeyProperty) {
        NSString *reason = [NSString stringWithFormat:@"'%@' does not have a primary key and can not be updated", object.objectSchema.className];
        @throw [NSException exceptionWithName:@"RLMExecption" reason:reason userInfo:nil];
    }

    RLMAddObjectToRealm(object, self, RLMCreationOptionsUpdateOrCreate);
}

- (void)addOrUpdateObjectsFromArray:(id)array {
    for (RLMObject *obj in array) {
        [self addOrUpdateObject:obj];
    }
}

- (void)deleteObject:(RLMObject *)object {
    RLMDeleteObjectFromRealm(object);
}

- (void)deleteObjects:(id)array {
    if (NSArray *nsArray = RLMDynamicCast<NSArray>(array)) {
        // for arrays and standalone delete each individually
        for (id obj in nsArray) {
            if ([obj isKindOfClass:RLMObjectBase.class]) {
                RLMDeleteObjectFromRealm(obj);
            }
        }
    }
    else if (RLMArray *rlmArray = RLMDynamicCast<RLMArray>(array)) {
        // call deleteObjectsFromRealm for our RLMArray
        [rlmArray deleteObjectsFromRealm];
    }
    else if (RLMResults *rlmResults = RLMDynamicCast<RLMResults>(array)) {
        // call deleteObjectsFromRealm for our RLMResults
        [rlmResults deleteObjectsFromRealm];
    }
    else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid array type - container must be an RLMArray, RLMArray, or NSArray of RLMObjects" userInfo:nil];
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

+ (void)setSchemaVersion:(NSUInteger)version withMigrationBlock:(RLMMigrationBlock)block {
    s_currentSchemaVersion = version;
    s_migrationBlock = block;
}

+ (NSError *)migrateRealmAtPath:(NSString *)realmPath {
    NSData *key;
    @synchronized (s_keysPerPath) {
        key = s_keysPerPath[realmPath];
    }

    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithPath:realmPath key:key readOnly:NO inMemory:NO dynamic:YES schema:nil error:&error];
    if (error) {
        return error;
    }

    return [self migrateRealm:realm key:key];
}

+ (NSError *)migrateEncryptedRealmAtPath:(NSString *)realmPath key:(NSData *)key {
    if (!key) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Encryption key must not be nil" userInfo:nil];
    }

    NSError *error;
    RLMRealm *realm = [self realmWithPath:realmPath key:key readOnly:NO inMemory:NO dynamic:YES schema:nil error:&error];
    if (error) {
        return error;
    }

    return [self migrateRealm:realm key:key];
}

+ (NSError *)migrateRealm:(RLMRealm *)realm key:(NSData *)key {
    NSError *error;
    RLMMigration *migration = [RLMMigration migrationForRealm:realm key:key error:&error];
    if (error) {
        return error;
    }

    // only perform migration if current version is > on-disk version
    NSUInteger schemaVersion = RLMRealmSchemaVersion(migration.realm);
    if (schemaVersion < s_currentSchemaVersion) {
        [migration migrateWithBlock:s_migrationBlock version:s_currentSchemaVersion];
    }
    else if (schemaVersion > s_currentSchemaVersion && schemaVersion != RLMNotVersioned) {
        if (!s_migrationBlock) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"No migration block specified for a Realm with a schema version greater than 0. You must supply a valid schema version and migration block before accessing any Realm by calling `setSchemaVersion:withMigrationBlock:`"
                                         userInfo:@{@"path" : migration.realm.path}];
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Realm version is higher than the current version provided to `setSchemaVersion:withMigrationBlock:`"
                                         userInfo:@{@"path" : migration.realm.path}];
        }
    }

    return nil;
}

- (RLMObject *)createObject:(NSString *)className withObject:(id)object {
    return (RLMObject *)RLMCreateObjectInRealmWithValue(self, className, object, RLMCreationOptionsNone);
}

+ (void)enableServerSyncOnPath:(NSString *)path serverBaseURL:(NSString *)serverBaseURL {
    NSURL *url = [NSURL URLWithString:serverBaseURL];
    // The URL must specify a scheme, a host, and a path, and the
    // scheme must be 'realm'.
    bool good = url && url.scheme && url.host && url.path &&
        !url.user && !url.query && !url.fragment &&
        [url.scheme.lowercaseString isEqualToString:@"realm"];
    if (!good)
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Bad URL" userInfo:nil];
    @synchronized (s_serverBaseURLS) {
        s_serverBaseURLS[path] = url;
    }
}

+ (void)setServerSyncLogLevel:(int)level {
    s_syncLogEverything = (level >= 2);
}

- (BOOL)writeCopyToPath:(NSString *)path key:(NSData *)key error:(NSError **)error {
    BOOL success = YES;

    try {
        self.group->write(path.UTF8String, static_cast<const char *>(key.bytes));
    }
    catch (File::PermissionDenied &ex) {
        success = NO;
        if (error) {
            *error = make_realm_error(RLMErrorFilePermissionDenied, ex);
        }
    }
    catch (File::Exists &ex) {
        success = NO;
        if (error) {
            *error = make_realm_error(RLMErrorFileExists, ex);
        }
    }
    catch (File::AccessError &ex) {
        success = NO;
        if (error) {
            *error = make_realm_error(RLMErrorFileAccessError, ex);
        }
    }
    catch (exception &ex) {
        success = NO;
        if (error) {
            *error = make_realm_error(RLMErrorFail, ex);
        }
    }

    return success;
}

- (BOOL)writeCopyToPath:(NSString *)path error:(NSError **)error {
    return [self writeCopyToPath:path key:nil error:error];
}

- (BOOL)writeEncryptedCopyToPath:(NSString *)path key:(NSData *)key error:(NSError **)error {
    if (!key) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Encryption key must not be nil" userInfo:nil];
    }

    return [self writeCopyToPath:path key:key error:error];
}

- (tightdb::SharedGroup *)sharedGroup {
    return _sharedGroup.get();
}

- (tightdb::Replication *)transactLogRegistry {
    return _replication.get();
}

@end

@implementation RLMWeakNotifier
- (instancetype)initWithRealm:(RLMRealm *)realm
{
    self = [super init];
    if (self) {
        _realm = realm;
    }
    return self;
}

- (void)notify
{
    [_realm handleExternalCommit];
}
@end
