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

// Access to s_serverFiles (referenced object),
// s_nextLocalFileIdent, s_serverConnections (referenced
// object), and s_backgroundOperationQueue (reference) must be
// synchronized with respect to s_realmsPerPath.
NSMapTable *s_serverFiles = [NSMapTable strongToWeakObjectsMapTable];
unsigned long s_nextLocalFileIdent = 0;
NSMapTable *s_serverConnections = [NSMapTable strongToWeakObjectsMapTable];

} // anonymous namespace


// Instances of RLMServerConnection and RLMServerFile may be created by any
// thread, but all instance methods must be called by the main thread, except
// backgroundThreadApplyTransactLog on RLMServerFile.

@interface RLMOutputMessage : NSObject
@property (nonatomic) NSString *head;
@property (nonatomic) NSData *body; // May be nil
@end

@interface RLMServerConnection : NSObject <NSStreamDelegate>
@property (readonly, nonatomic) BOOL isConnected;
@end

@interface RLMServerFile : NSObject
@property (readonly, nonatomic) RLMServerConnection *connection;
- (void)connected;
- (void)handleTransactMessageWithVersion:(Replication::version_type)version andData:(NSData *)data;
- (void)handleAcceptMessageWithVersion:(Replication::version_type)version;
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
    BOOL _isConnected;

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

    // Maps a file identifier to an RLMServerFile instance. A file
    // identifier is a locally assigned integer that uniquely
    // identifies the RLMServerFile instance. Two instances must have
    // different identifiers even if their lifetimes do not overlap.
    NSMapTable *_files;
}


- (instancetype)initWithAddress:(NSString *)address port:(NSNumber *)port {
    self = [super init];
    if (self) {
        _isConnected = NO;

        _address = address;
        _port = port ? port : [NSNumber numberWithInt:7800];

        _runLoop = nil;

        _inputBufferSize = 1024;
        _inputBuffer = make_unique<char[]>(_inputBufferSize);

        _headBufferSize = 32;
        _headBuffer = make_unique<char[]>(_headBufferSize);

        _currentOutputChunk = nil;
        _nextOutputChunk = nil;
        _outputCompletionHandler = nil;

        _files = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}


- (void)mainThreadInit {
    // Called by main thread
    if (_runLoop)
        return;
    _runLoop = [NSRunLoop currentRunLoop];

    [self open];
}


- (void)open {
    if (_isConnected)
        return;

    NSLog(@"Opening connection to %@:%@", _address, _port);

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

    _isConnected = YES;

    for(NSNumber *ident in _files) {
        RLMServerFile *file = [_files objectForKey:ident];
        [file connected];
    }
}


- (void)close {
    if (!_isConnected)
        return;

    [_inputStream close];
    [_outputStream close];

    _inputStream  = nil;
    _outputStream = nil;

    _outputQueue = nil;
    _currentOutputChunk = nil;
    _nextOutputChunk = nil;
    _outputCompletionHandler = nil;

    _isConnected = NO;

    NSLog(@"Closed connection to %@:%@", _address, _port);

    // FIXME: Retry opening the connection after a delay, maybe with
    // a progressively growing delay.
}


- (void)addFile:(RLMServerFile *)file withIdent:(NSNumber *)ident {
    [_files setObject:file forKey:ident];
    if (_isConnected)
        [file connected];
}


- (void)sendBindMessageWithIdent:(NSNumber *)ident version:(Replication::version_type)version
                      remotePath:(NSString *)remotePath {
    typedef unsigned long ulong;
    typedef unsigned long long ulonglong;
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.body = [remotePath dataUsingEncoding:NSUTF8StringEncoding];
    msg.head = [NSString stringWithFormat:@"bind %@ %llu %lu\n",
                         ident, ulonglong(version), ulong(msg.body.length)];
    [self enqueueOutputMessage:msg];
    NSLog(@"Sending: Bind local file #%@ at version %llu to remote file '%@'",
          ident, ulonglong(version), remotePath);
}


- (void)sendUnbindMessageWithIdent:(NSNumber *)ident {
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.head = [NSString stringWithFormat:@"unbind %@\n", ident];
    [self enqueueOutputMessage:msg];
    NSLog(@"Sending: Unbind local file #%@", ident);
}


- (void)enqueueOutputMessage:(RLMOutputMessage *)msg {
    [_outputQueue addObject:msg];
    if (_isConnected && !_currentOutputChunk) {
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
                NSLog(@"Error reading from socket: %@", _inputStream.streamError);
                // FIXME: Report the error, close the connection, and try to reconnect later
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
                        NSLog(@"Message head too big");
                        // FIXME: Report the error, close the connection, and try to reconnect later
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
                    if (message_type == "transact") {
                        // A new foreign changeset is available for download
                        unsigned long fileIdent = 0;
                        Replication::version_type version = 0;
                        size_t logSize = 0;
                        char sp1, sp2, sp3;
                        parser >> sp1 >> fileIdent >> sp2 >> version >> sp3 >> logSize;
                        if (!parser || !parser.eof() || sp1 != ' ' || sp2 != ' ' || sp3 != ' ') {
                            NSLog(@"Bad 'transact' message from server");
                            // FIXME: Report the error, close the connection, and try to reconnect later
                            return;
                        }
                        _messageBodySize = logSize;
                        _messageHandler = ^{
                            NSNumber *fileIdent2 = [NSNumber numberWithUnsignedLong:fileIdent];
                            [weakSelf handleTransactMessageWithFileIdent:fileIdent2
                                                              andVersion:version];
                        };
                    }
                    else if (message_type == "accept") {
                        // Server accepts a previously uploaded changeset
                        unsigned long fileIdent = 0;
                        Replication::version_type version = 0;
                        char sp1, sp2;
                        parser >> sp1 >> fileIdent >> sp2 >> version;
                        if (!parser || !parser.eof() || sp1 != ' ' || sp2 != ' ') {
                            NSLog(@"Bad 'accept' message from server");
                            // FIXME: Report the error, close the connection, and try to reconnect later
                            return;
                        }
                        NSNumber *fileIdent2 = [NSNumber numberWithUnsignedLong:fileIdent];
                        [self handleAcceptMessageWithFileIdent:fileIdent2
                                                    andVersion:version];
                    }
                    else {
                        NSLog(@"Unknown message from server");
                        // FIXME: Report the error, close the connection, and try to reconnect later
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
                    if (!_isConnected)
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
                NSLog(@"Error writing to socket: %@", _outputStream.streamError);
                // FIXME: Report the error, close the connection, and try to reconnect later
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
            NSLog(@"Server closed connection");
            // FIXME: Report the error, and try to reconnect later
            return;
        }
        case NSStreamEventErrorOccurred: {
            if (stream != _inputStream && stream != _outputStream)
                return;
            NSLog(@"Socket error: %@", _outputStream.streamError);
            // FIXME: Report the error, close the connection, and try to reconnect later
            return;
        }
    }
}


- (void)handleTransactMessageWithFileIdent:(NSNumber *)fileIdent
                                andVersion:(Replication::version_type)version {
    typedef unsigned long long ulonglong;
#ifdef TIGHTDB_DEBUG
    NSLog(@"Received: Foreign changeset %llu -> %llu for local file #%@",
          ulonglong(version-1), ulonglong(version), fileIdent);
#endif

    RLMServerFile *file = [_files objectForKey:fileIdent];
    if (!file)
        return;

    NSData *data = _messageBodyBuffer;
    _messageBodyBuffer = nil;

    [file handleTransactMessageWithVersion:version andData:data];
}


- (void)handleAcceptMessageWithFileIdent:(NSNumber *)fileIdent
                              andVersion:(Replication::version_type)version {
    typedef unsigned long long ulonglong;
#ifdef TIGHTDB_DEBUG
    NSLog(@"Received: Accept changeset %llu -> %llu on local file #%@",
          ulonglong(version-1), ulonglong(version), fileIdent);
#endif

    RLMServerFile *file = [_files objectForKey:fileIdent];
    if (!file)
        return;

    [file handleAcceptMessageWithVersion:version];
}

@end


@implementation RLMServerFile {
    NSNumber *_ident;
    NSString *_localPath;
    NSString *_remotePath;

    unique_ptr<SharedGroup> _sharedGroup;
    unique_ptr<Replication> _transactLogRegistry;

    unique_ptr<SharedGroup> _backgroundSharedGroup;
    unique_ptr<Replication> _backgroundTransactLogRegistry;

    Replication::version_type _latestVersionAvailable;
    Replication::version_type _latestVersionUploaded;
    Replication::version_type _latestVersionIntegratedByServer;
    BOOL _uploadInProgress;

    NSOperationQueue *_backgroundOperationQueue;
}


- (instancetype)initWithConnection:(RLMServerConnection *)connection
                        localIdent:(NSNumber *)ident
                         localPath:(NSString *)localPath
                        remotePath:(NSString *)remotePath {
    self = [super init];
    if (self) {
        _connection = connection;
        _ident = ident;
        _localPath = localPath;
        _remotePath = remotePath;

        bool serverSynchronizationMode = true;
        SharedGroup::DurabilityLevel durability = SharedGroup::durability_Full;
        _transactLogRegistry.reset(makeWriteLogCollector(localPath.UTF8String,
                                                         serverSynchronizationMode));
        _sharedGroup = make_unique<SharedGroup>(*_transactLogRegistry, durability);
        _backgroundTransactLogRegistry.reset(makeWriteLogCollector(localPath.UTF8String,
                                                                   serverSynchronizationMode));
        _backgroundSharedGroup = make_unique<SharedGroup>(*_backgroundTransactLogRegistry, durability);

        _uploadInProgress = NO;

        _backgroundOperationQueue = [[NSOperationQueue alloc] init];
        _backgroundOperationQueue.name = @"io.realm.sync";
        _backgroundOperationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}


- (void)mainThreadInit {
    // Called by main thread
    _latestVersionIntegratedByServer = _transactLogRegistry->get_last_version_synced();
    _latestVersionUploaded = _latestVersionIntegratedByServer;
    _latestVersionAvailable = LangBindHelper::get_current_version(*_sharedGroup);
    if (_latestVersionUploaded > _latestVersionAvailable) // Transiently possible
        _latestVersionUploaded = _latestVersionAvailable;

    [_connection mainThreadInit];
    [_connection addFile:self withIdent:_ident];
}


- (void)refreshLatestVersionAvailable {
    _latestVersionAvailable = LangBindHelper::get_current_version(*_sharedGroup);
    [self resumeUpload];
}


- (void)connected {
    _latestVersionUploaded = _latestVersionIntegratedByServer;
    [_connection sendBindMessageWithIdent:_ident version:_latestVersionIntegratedByServer
                               remotePath:_remotePath];
    [self resumeUpload];
}


- (void)resumeUpload {
    if (_uploadInProgress || !_connection.isConnected)
        return;
    _uploadInProgress = YES;

    // Fetch and copy the next changset, and produce an output message
    // from it.  Set the completionHandler to a block that calls
    // resumeUpload.
    Replication::version_type uploadVersion;
    Replication::CommitLogEntry changeset;
    for (;;) {
        TIGHTDB_ASSERT(_latestVersionUploaded <= _latestVersionAvailable);
        if (_latestVersionUploaded == _latestVersionAvailable) {
            _uploadInProgress = NO;
            return;
        }
        uploadVersion = _latestVersionUploaded + 1;
        _transactLogRegistry->get_commit_entries(uploadVersion-1, uploadVersion, &changeset);
        // Skip changesets that were downloaded from the server
        if (!changeset.is_foreign)
            break;
        _latestVersionUploaded = uploadVersion;
    }
    typedef unsigned long ulong;
    typedef unsigned long long ulonglong;
    RLMOutputMessage *msg = [[RLMOutputMessage alloc] init];
    msg.body = [NSData dataWithBytes:changeset.log_data.data() length:changeset.log_data.size()]; // Full copy
    msg.head = [NSString stringWithFormat:@"transact %@ %llu %lu\n",
                         _ident, ulonglong(uploadVersion), ulong(msg.body.length)];
#ifdef TIGHTDB_DEBUG
    NSLog(@"Sending: Changeset %llu -> %llu of size %lu on local file #%@",
          ulonglong(uploadVersion-1), ulonglong(uploadVersion), ulong(msg.body.length), _ident);
#endif
    __weak RLMServerFile *weakSelf = self;
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
    [self resumeUpload];
}


- (void)handleTransactMessageWithVersion:(Replication::version_type)version
                                 andData:(NSData *)data {
    Replication::version_type expectedVersion = _latestVersionIntegratedByServer + 1;
    if (version != expectedVersion) {
        typedef unsigned long long ulonglong;
        NSLog(@"ERROR: Bad version %llu in changeset message (expected %llu)",
              ulonglong(version), ulonglong(expectedVersion));
        [_connection close];
        return;
    }
    _latestVersionIntegratedByServer = version;

    // FIXME: Consider whether we should attempt to apply small
    // transactions immediately on the main thread (right here) if
    // auto-refresh is enabled, `s_backgroundOperationQueue` is empty,
    // and a try-lock on the write-transaction mutex succeeds. This
    // might be an effective way of reducing latency due to context
    // switches.

    [self addBackgroundTaskWithVersion:version andData:data];
}


- (void)handleAcceptMessageWithVersion:(Replication::version_type)version {
    Replication::version_type expectedVersion = _latestVersionIntegratedByServer + 1;
    if (version != expectedVersion) {
        typedef unsigned long long ulonglong;
        NSLog(@"ERROR: Bad version %llu in accept message (expected %llu)",
              ulonglong(version), ulonglong(expectedVersion));
        [_connection close];
        return;
    }
    _latestVersionIntegratedByServer = version;

    [self addBackgroundTaskWithVersion:version andData:nil];
}


- (void)addBackgroundTaskWithVersion:(Replication::version_type)version andData:(NSData *)data {
    __weak RLMServerFile *weakSelf = self;
    [_backgroundOperationQueue addOperationWithBlock:^{
            [weakSelf backgroundTaskWithVersion:version andData:data];
        }];
}


- (void)backgroundTaskWithVersion:(Replication::version_type)version andData:(NSData *)data {
    if (data)
        [self backgroundApplyChangesetWithVersion:version andData:data];

    __weak RLMServerFile *weakSelf = self;
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [mainQueue addOperationWithBlock:^{
            [weakSelf markVersionIntegratedByServer:version];
        }];
}


- (void)backgroundApplyChangesetWithVersion:(Replication::version_type)version
                                    andData:(NSData *)data {
    typedef unsigned long long ulonglong;
    Replication::version_type baseVersion = version - 1;
    const char *data2 = static_cast<const char *>(data.bytes);
    size_t size = data.length;
    BinaryData transactLog(data2, size);
    ostream *applyLog = 0;
    BOOL conflict;
    try {
        Replication &repl = *_backgroundTransactLogRegistry;
        Replication::version_type serverVersion = 0; // Value is imaterial for now
        Replication::version_type newVersion =
            repl.apply_foreign_changeset(*_backgroundSharedGroup, baseVersion,
                                         transactLog, serverVersion, applyLog);
        conflict = (newVersion == 0);
        TIGHTDB_ASSERT(conflict || newVersion == version);
    }
    catch (Replication::BadTransactLog&) {
        NSString *message = [NSString stringWithFormat:@"Application of changeset (%llu -> %llu) "
                                      "failed", ulonglong(baseVersion), ulonglong(baseVersion+1)];
        @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil];
    }

    if (!conflict) {
#ifdef TIGHTDB_DEBUG
        NSLog(@"Foreign changeset (%llu -> %llu) applied",
              ulonglong(baseVersion), ulonglong(baseVersion+1));
#endif
        [RLMRealm notifyRealmsAtPath:_localPath exceptRealm:nil];
        return;
    }

    BinaryData changeset(static_cast<const char*>(data.bytes), data.length);
    Replication::CommitLogEntry conflictingChangeset;
    _backgroundTransactLogRegistry->get_commit_entries(baseVersion, baseVersion+1,
                                                       &conflictingChangeset);
    if (conflictingChangeset.is_foreign) {
        // Assuming resend of previously integrated changelog
        TIGHTDB_ASSERT(conflictingChangeset.log_data == changeset);
        NSLog(@"Skipping previously applied foreign changeset (%llu -> %llu)",
              ulonglong(baseVersion), ulonglong(baseVersion+1));
        return;
    }

    // WARNING: Strictly speaking, the following is not the correct
    // resulution of the conflict between two identical initial
    // transactions, but it is done as a temporary workaround to allow
    // the current version of this binding to carry out an initial
    // schema creating transaction without getting into an immediate
    // unrecoverable conflict. It does not work in general as even the
    // initial transaction is allowed to contain elements that are
    // additive rather than idempotent.
    BOOL isInitialTransact = (baseVersion == 1); // Schema creation
    if (isInitialTransact && conflictingChangeset.log_data == changeset) {
        NSLog(@"Conflict on identical initial transactions resolved (impropperly)");
        return;
    }

    NSString *message = [NSString stringWithFormat:@"Conflicting foreign changeset (%llu -> %llu)",
                                  ulonglong(baseVersion), ulonglong(baseVersion+1)];
    @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil];
}


- (void)markVersionIntegratedByServer:(Replication::version_type)version {
    _transactLogRegistry->set_last_version_synced(version);
}


- (void)dealloc {
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    __weak RLMServerConnection *weakConnection = _connection;
    NSNumber *ident = _ident;
    [mainQueue addOperationWithBlock:^{
            [weakConnection sendUnbindMessageWithIdent:ident];
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
    RLMServerFile *_serverFile;
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
                    realm->_serverFile = sourceRealm->_serverFile;
                }
            }
            else {
                RLMServerFile *file = 0;
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
                file = [s_serverFiles objectForKey:realm.path];
                if (!file) {
                    if (serverBaseURL) {
                        NSString *hostKey = serverBaseURL.host;
                        if (serverBaseURL.port) {
                            hostKey = [NSString stringWithFormat:@"%@:%@", serverBaseURL.host, serverBaseURL.port];
                        }
                        RLMServerConnection *conn = [s_serverConnections objectForKey:hostKey];
                        if (!conn) {
                            conn = [[RLMServerConnection alloc] initWithAddress:serverBaseURL.host
                                                                           port:serverBaseURL.port];
                            [s_serverConnections setObject:conn forKey:hostKey];
                        }
                        NSNumber *localFileIdent = [NSNumber numberWithUnsignedLong:++s_nextLocalFileIdent];
                        file = [[RLMServerFile alloc] initWithConnection:conn
                                                              localIdent:localFileIdent
                                                               localPath:realm.path
                                                              remotePath:serverBaseURL.path];
                        [s_serverFiles setObject:file forKey:realm.path];
                        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
                        __weak RLMServerFile *weakFile = file;
                        [mainQueue addOperationWithBlock:^{
                                [weakFile mainThreadInit];
                            }];
                    }
                }
                realm->_serverFile = file;

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
            __weak RLMServerFile *weakFile = _serverFile;
            [mainQueue addOperationWithBlock:^{
                    [weakFile refreshLatestVersionAvailable];
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
