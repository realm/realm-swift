////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncConfiguration_Private.hpp"

#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration_Private.h"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealmUtil.hpp"
#import "RLMSchema_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/sync/sync_session.hpp>
#import <realm/sync/config.hpp>
#import <realm/sync/protocol.hpp>
#import <realm/util/ez_websocket.hpp>

using namespace realm;

API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0))
@interface RLMCocoaSocketDelegate : NSObject<NSURLSessionWebSocketDelegate>
@property realm::util::websocket::EZObserver* observer;
@end

@implementation RLMCocoaSocketDelegate

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didOpenWithProtocol:(NSString *)protocol {
    _observer->websocket_handshake_completion_handler([protocol cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void)URLSession:(NSURLSession *)session webSocketTask:(NSURLSessionWebSocketTask *)webSocketTask didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode reason:(NSData *)reason {
    _observer->websocket_close_message_received(std::make_error_code(std::errc::connection_aborted),
                                                RLMStringDataWithNSString([[NSString alloc] initWithData: reason encoding:NSUTF8StringEncoding]));
}

@end

namespace realm::util::websocket {
class API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0)) CocoaSocket: public EZSocket {

public:
    CocoaSocket(EZConfig config, EZObserver* observer, EZEndpoint&& endpoint):
    m_config(config)
    , delegate([RLMCocoaSocketDelegate new])
    {
        setup(observer, std::move(endpoint));
    }

    RLMCocoaSocketDelegate *delegate;
    NSURLSessionWebSocketTask *task;

    util::Logger& logger() const
    {
        return m_config.logger;
    }

    void async_write_binary(const char *data, size_t size, util::UniqueFunction<void ()> &&handler) override
    {
        logger().info(">>> CocoaSocket async_write_binary");
        [task sendMessage:[[NSURLSessionWebSocketMessage alloc] initWithString:@(data)]
        completionHandler:^(NSError * _Nullable error) {
            handler();
        }];
    }

private:

    NSURL *buildUrl(EZEndpoint endpoint) {
        NSMutableArray<NSString *> *strs = [NSMutableArray<NSString *> new];
//        endpoint.is_ssl ? [strs addObject: @"wss://"] : [strs addObject: @"ws://"];
        [strs addObject: @"ws://"];
        endpoint.proxy ? [strs addObject: @(endpoint.proxy->address.data())] : [strs addObject: @(endpoint.address.data())];
        endpoint.proxy ? [strs addObject: [NSString stringWithFormat:@":%u", endpoint.proxy->port]] : [strs addObject: [NSString stringWithFormat:@":%u", endpoint.port]];
        [strs addObject:@(endpoint.path.data())];
        logger().info("Connect to '%1'", [[strs componentsJoinedByString:@""] cStringUsingEncoding:NSUTF8StringEncoding]);
        return [[NSURL alloc] initWithString:[strs componentsJoinedByString:@""]];
    }

    void setup(EZObserver* observer, EZEndpoint&& endpoint)
    {
        logger().info(">>> CocoaSocket setup");
        delegate.observer = observer;
        NSURLSession *session = [NSURLSession sharedSession];
        
        task = [session webSocketTaskWithURL:buildUrl(endpoint)];
        [task receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage * _Nullable message, NSError * _Nullable error) {
            if (error) {
                logger().error("Failed to connect to endpoint '%1:%2'", endpoint.address, endpoint.proxy->port); // Throws
//                observer->websocket_connect_error_handler(ec); // Throws
                return;
            }
            switch (message.type) {
                case NSURLSessionWebSocketMessageTypeData:
                    observer->websocket_binary_message_received([[[NSString alloc] initWithData:message.data encoding:NSUTF8StringEncoding] UTF8String],
                                                                [message.data length]);
                    break;
                case NSURLSessionWebSocketMessageTypeString:
                    observer->websocket_binary_message_received([message.string UTF8String],
                                                                [message.data length]);
                    break;
            }
        }];
        [task resume];
    }

    EZConfig m_config;
};

class API_AVAILABLE(ios(13.0), macos(10.15), tvos(13.0), watchos(6.0)) CocoaSocketFactory: public EZSocketFactory {
public:
    CocoaSocketFactory(EZConfig config)
        : EZSocketFactory(config)
    , m_config(config)
    {
    }

    std::unique_ptr<EZSocket> connect(EZObserver* observer, EZEndpoint&& endpoint) override
    {
        return std::unique_ptr<EZSocket>(new CocoaSocket(std::move(m_config), observer, std::move(endpoint)));
    }
    
private:
    EZConfig m_config;
};
}

namespace {
using ProtocolError = realm::sync::ProtocolError;

RLMSyncSystemErrorKind errorKindForSyncError(SyncError error) {
    if (error.is_client_reset_requested()) {
        return RLMSyncSystemErrorKindClientReset;
    } else if (error.error_code == ProtocolError::permission_denied) {
        return RLMSyncSystemErrorKindPermissionDenied;
    } else if (error.error_code == ProtocolError::bad_authentication) {
        return RLMSyncSystemErrorKindUser;
    } else if (error.is_session_level_protocol_error()) {
        return RLMSyncSystemErrorKindSession;
    } else if (error.is_connection_level_protocol_error()) {
        return RLMSyncSystemErrorKindConnection;
    } else if (error.is_client_error()) {
        return RLMSyncSystemErrorKindClient;
    } else {
        return RLMSyncSystemErrorKindUnknown;
    }
}

struct CallbackSchema {
    bool dynamic;
    std::string path;
    RLMSchema *customSchema;

    RLMSchema *getSchema(Realm& realm) {
        if (dynamic) {
            return [RLMSchema dynamicSchemaFromObjectStoreSchema:realm.schema()];
        }
        if (auto cached = RLMGetAnyCachedRealmForPath(path)) {
            return cached.schema;
        }
        return customSchema ?: RLMSchema.sharedSchema;
    }
};

struct BeforeClientResetWrapper : CallbackSchema {
    RLMClientResetBeforeBlock block;
    void operator()(std::shared_ptr<Realm> local) {
        @autoreleasepool {
            block([RLMRealm realmWithSharedRealm:local schema:getSchema(*local) dynamic:false]);
        }
    }
};

struct AfterClientResetWrapper : CallbackSchema {
    RLMClientResetAfterBlock block;
    void operator()(std::shared_ptr<Realm> local, std::shared_ptr<Realm> remote) {
        @autoreleasepool {
            RLMSchema *schema = getSchema(*local);
            RLMRealm *localRealm = [RLMRealm realmWithSharedRealm:local
                                                           schema:schema
                                                          dynamic:false];

            RLMRealm *remoteRealm = [RLMRealm realmWithSharedRealm:remote
                                                            schema:schema
                                                           dynamic:false];
            block(localRealm, remoteRealm);
        }
    }
};
} // anonymous namespace

@interface RLMSyncConfiguration () {
    std::unique_ptr<realm::SyncConfig> _config;
}

@end

@implementation RLMSyncConfiguration

@dynamic stopPolicy;

- (instancetype)initWithRawConfig:(realm::SyncConfig)config {
    if (self = [super init]) {
        _config = std::make_unique<realm::SyncConfig>(std::move(config));
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMSyncConfiguration class]]) {
        return NO;
    }
    RLMSyncConfiguration *that = (RLMSyncConfiguration *)object;
    return [self.partitionValue isEqual:that.partitionValue]
    && [self.user isEqual:that.user]
    && self.stopPolicy == that.stopPolicy;
}

- (realm::SyncConfig&)rawConfiguration {
    return *_config;
}

- (RLMUser *)user {
    RLMApp *app = [RLMApp appWithId:@(_config->user->sync_manager()->app().lock()->config().app_id.data())];
    return [[RLMUser alloc] initWithUser:_config->user app:app];
}

- (RLMSyncStopPolicy)stopPolicy {
    return translateStopPolicy(_config->stop_policy);
}

- (void)setStopPolicy:(RLMSyncStopPolicy)stopPolicy {
    _config->stop_policy = translateStopPolicy(stopPolicy);
}

- (RLMClientResetMode)clientResetMode {
    return RLMClientResetMode(_config->client_resync_mode);
}

- (RLMClientResetBeforeBlock)beforeClientReset {
    if (_config->notify_before_client_reset) {
        auto wrapper = _config->notify_before_client_reset.target<BeforeClientResetWrapper>();
        return wrapper->block;
    } else {
        return nil;
    }
}

- (void)setBeforeClientReset:(RLMClientResetBeforeBlock)beforeClientReset {
    if (!beforeClientReset) {
        _config->notify_before_client_reset = nullptr;
    } else if (self.clientResetMode == RLMClientResetModeManual) {
        @throw RLMException(@"Client reset notifications not supported in Manual mode. Use SyncManager.ErrorHandler");
    } else {
        _config->notify_before_client_reset = BeforeClientResetWrapper{.block = beforeClientReset};
    }
}

- (RLMClientResetAfterBlock)afterClientReset {
    if (_config->notify_after_client_reset) {
        auto wrapper = _config->notify_after_client_reset.target<AfterClientResetWrapper>();
        return wrapper->block;
    } else {
        return nil;
    }
}

- (void)setAfterClientReset:(RLMClientResetAfterBlock)afterClientReset {
    if (!afterClientReset) {
        _config->notify_after_client_reset = nullptr;
    } else if (self.clientResetMode == RLMClientResetModeManual) {
        @throw RLMException(@"Client reset notifications not supported in Manual mode. Use SyncManager.ErrorHandler");
    } else {
        _config->notify_after_client_reset = AfterClientResetWrapper{.block = afterClientReset};
    }
}

void RLMSetConfigInfoForClientResetCallbacks(realm::SyncConfig& syncConfig, RLMRealmConfiguration *config) {
    if (syncConfig.notify_before_client_reset) {
        auto before = syncConfig.notify_before_client_reset.target<BeforeClientResetWrapper>();
        before->dynamic = config.dynamic;
        before->path = config.path;
        before->customSchema = config.customSchema;
    }
    if (syncConfig.notify_after_client_reset) {
        auto after = syncConfig.notify_after_client_reset.target<AfterClientResetWrapper>();
        after->dynamic = config.dynamic;
        after->path = config.path;
        after->customSchema = config.customSchema;
    }
}

- (id<RLMBSON>)partitionValue {
    if (!_config->partition_value.empty()) {
        return RLMConvertBsonToRLMBSON(realm::bson::parse(_config->partition_value.c_str()));
    }
    return nil;
}

- (bool)cancelAsyncOpenOnNonFatalErrors {
    return _config->cancel_waits_on_nonfatal_error;
}

- (void)setCancelAsyncOpenOnNonFatalErrors:(bool)cancelAsyncOpenOnNonFatalErrors {
    _config->cancel_waits_on_nonfatal_error = cancelAsyncOpenOnNonFatalErrors;
}

- (BOOL)enableFlexibleSync {
    return _config->flx_sync_requested;
}

- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue {
    return [self initWithUser:user
               partitionValue:partitionValue
                customFileURL:nil
                   stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
           enableFlexibleSync:false
              clientResetMode:RLMClientResetModeManual
            notifyBeforeReset:nil 
             notifyAfterReset:nil];
}

- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
             clientResetMode:(RLMClientResetMode)clientResetMode
           notifyBeforeReset:(nullable RLMClientResetBeforeBlock)beforeResetBlock
            notifyAfterReset:(nullable RLMClientResetAfterBlock)afterResetBlock {
    auto config = [self initWithUser:user
                      partitionValue:partitionValue
                       customFileURL:nil
                          stopPolicy:stopPolicy
                  enableFlexibleSync:false
                     clientResetMode:clientResetMode
                   notifyBeforeReset:beforeResetBlock
                    notifyAfterReset:afterResetBlock];
    return config;
}

- (instancetype)initWithUser:(RLMUser *)user
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
          enableFlexibleSync:(BOOL)enableFlexibleSync {
    auto config = [self initWithUser:user
                      partitionValue:nil
                       customFileURL:nil
                          stopPolicy:stopPolicy
                  enableFlexibleSync:enableFlexibleSync
                     clientResetMode:RLMClientResetModeManual
                   notifyBeforeReset:nil
                    notifyAfterReset:nil];
    return config;
}



- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue
             clientResetMode:(RLMClientResetMode)clientResetMode {
    auto config = [self initWithUser:user
                      partitionValue:partitionValue
                       customFileURL:nil
                          stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                  enableFlexibleSync:false
                     clientResetMode:clientResetMode
                   notifyBeforeReset:nil
                    notifyAfterReset:nil];
    return config;
}

- (instancetype)initWithUser:(RLMUser *)user
          enableFlexibleSync:(BOOL)enableFlexibleSync
             clientResetMode:(RLMClientResetMode)clientResetMode {
    auto config = [self initWithUser:user
                      partitionValue:nil
                       customFileURL:nil
                          stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                  enableFlexibleSync:enableFlexibleSync
                     clientResetMode:clientResetMode
                   notifyBeforeReset:nil
                    notifyAfterReset:nil];
    return config;
}

- (instancetype)initWithUser:(RLMUser *)user
              partitionValue:(nullable id<RLMBSON>)partitionValue
               customFileURL:(nullable NSURL *)customFileURL
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
          enableFlexibleSync:(BOOL)enableFlexibleSync
             clientResetMode:(RLMClientResetMode)clientResetMode
           notifyBeforeReset:(RLMClientResetBeforeBlock)beforeResetBlock
            notifyAfterReset:(RLMClientResetAfterBlock)afterResetBlock {
    if (self = [super init]) {
        if (enableFlexibleSync) {
            _config = std::make_unique<SyncConfig>([user _syncUser], SyncConfig::FLXSyncEnabled{});
        } else {
            std::stringstream s;
            s << RLMConvertRLMBSONToBson(partitionValue);
            _config = std::make_unique<SyncConfig>([user _syncUser],
                                                   s.str());
        }
        _config->stop_policy = translateStopPolicy(stopPolicy);
        RLMSyncManager *manager = [user.app syncManager];
        __weak RLMSyncManager *weakManager = manager;
        _config->error_handler = [weakManager](std::shared_ptr<SyncSession> errored_session, SyncError error) {
            NSString *recoveryPath;
            RLMSyncErrorActionToken *token;
            for (auto& pair : error.user_info) {
                if (pair.first == realm::SyncError::c_original_file_path_key) {
                    token = [[RLMSyncErrorActionToken alloc] initWithOriginalPath:pair.second];
                }
                else if (pair.first == realm::SyncError::c_recovery_file_path_key) {
                    recoveryPath = @(pair.second.c_str());
                }
            }

            BOOL shouldMakeError = YES;
            NSDictionary *custom = nil;
            // Note that certain types of errors are 'interactive'; users have several options
            // as to how to proceed after the error is reported.
            auto errorClass = errorKindForSyncError(error);
            switch (errorClass) {
                case RLMSyncSystemErrorKindClientReset: {
                    custom = @{kRLMSyncPathOfRealmBackupCopyKey: recoveryPath, kRLMSyncErrorActionTokenKey: token};
                    break;
                }
                case RLMSyncSystemErrorKindPermissionDenied: {
                    if (token) {
                        custom = @{kRLMSyncErrorActionTokenKey: token};
                    }
                    break;
                }
                case RLMSyncSystemErrorKindUser:
                case RLMSyncSystemErrorKindSession:
                    break;
                case RLMSyncSystemErrorKindConnection:
                case RLMSyncSystemErrorKindClient:
                case RLMSyncSystemErrorKindUnknown:
                    // Report the error. There's nothing the user can do about it, though.
                    shouldMakeError = error.is_fatal;
                    break;
            }

            RLMSyncErrorReportingBlock errorHandler;
            @autoreleasepool {
                errorHandler = weakManager.errorHandler;
            }
            if (!shouldMakeError || !errorHandler) {
                return;
            }
            NSError *nsError = make_sync_error(errorClass, @(error.message.c_str()), error.error_code.value(), custom);
            RLMSyncSession *session = [[RLMSyncSession alloc] initWithSyncSession:errored_session];
            dispatch_async(dispatch_get_main_queue(), ^{
                errorHandler(nsError, session);
            });
        };
        // Default to manual mode
        _config->client_resync_mode = realm::ClientResyncMode(clientResetMode);
        self.beforeClientReset = beforeResetBlock;
        self.afterClientReset = afterResetBlock;

        if (NSString *authorizationHeaderName = manager.authorizationHeaderName) {
            _config->authorization_header_name.emplace(authorizationHeaderName.UTF8String);
        }
        if (NSDictionary<NSString *, NSString *> *customRequestHeaders = manager.customRequestHeaders) {
            for (NSString *key in customRequestHeaders) {
                _config->custom_http_headers.emplace(key.UTF8String, customRequestHeaders[key].UTF8String);
            }
        }

        _config->socket_factory = defaultSocketFactory();
        self.customFileURL = customFileURL;
        return self;
    }
    return nil;
}

@end

using namespace realm::util::websocket;

std::function<std::unique_ptr<EZSocketFactory>(EZConfig&&)> defaultSocketFactory() {
    return [](EZConfig&& config) mutable {
        if (@available(macOS 10.15, *)) {
            return std::unique_ptr<EZSocketFactory>(new CocoaSocketFactory(std::move(config)));
        } else {
            return std::unique_ptr<EZSocketFactory>(new EZSocketFactory(std::move(config)));
        }
    };
}
