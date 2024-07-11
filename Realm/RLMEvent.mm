////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import <Realm/RLMEvent.h>

#import "RLMError_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealmUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/audit.hpp>
#import <realm/object-store/audit_serializer.hpp>
#import <realm/object-store/sync/app.hpp>
#import <realm/object-store/sync/app_user.hpp>
#import <external/json/json.hpp>

using namespace realm;

@interface RLMObjectBase ()
- (NSString *)customEventRepresentation;
@end

namespace {
util::UniqueFunction<void (std::exception_ptr)> wrapCompletion(void (^completion)(NSError *)) {
    if (!completion) {
        return nullptr;
    }
    return [=](std::exception_ptr err) {
        @autoreleasepool {
            if (!err) {
                return completion(nil);
            }
            try {
                std::rethrow_exception(err);
            }
            catch (NSException *e) {
                auto info = @{@"ExceptionName": e.name ?: NSNull.null,
                              @"ExceptionReason": e.reason ?: NSNull.null,
                              @"ExceptionCallStackReturnAddresses": e.callStackReturnAddresses,
                              @"ExceptionCallStackSymbols": e.callStackSymbols,
                              @"ExceptionUserInfo": e.userInfo ?: NSNull.null};
                completion([NSError errorWithDomain:RLMErrorDomain code:RLMErrorFail userInfo:info]);
            }
            catch (...) {
                NSError *error;
                RLMRealmTranslateException(&error);
                completion(error);
            }
        }
    };
}

realm::AuditInterface *auditContext(RLMEventContext *context) {
    return reinterpret_cast<realm::AuditInterface *>(context);
}

std::vector<std::pair<std::string, std::string>> convertMetadata(NSDictionary *metadata) {
    std::vector<std::pair<std::string, std::string>> ret;
    ret.reserve(metadata.count);
    [metadata enumerateKeysAndObjectsUsingBlock:[&](NSString *key, NSString *value, BOOL *) {
        ret.emplace_back(key.UTF8String, value.UTF8String);
    }];
    return ret;
}

std::optional<std::string> nsStringToOptionalString(NSString *str) {
    if (!str) {
        return util::none;
    }

    std::string ret;
    RLMNSStringToStdString(ret, str);
    return ret;
}
} // anonymous namespace

uint64_t RLMEventBeginScope(RLMEventContext *context, NSString *activity) {
    return auditContext(context)->begin_scope(activity.UTF8String);
}

void RLMEventCommitScope(RLMEventContext *context, uint64_t scope_id, RLMEventCompletion completion) {
    auditContext(context)->end_scope(scope_id, wrapCompletion(completion));
}

void RLMEventCancelScope(RLMEventContext *context, uint64_t scope_id) {
    auditContext(context)->cancel_scope(scope_id);
}

bool RLMEventIsActive(RLMEventContext *context, uint64_t scope_id) {
    return auditContext(context)->is_scope_valid(scope_id);
}

void RLMEventRecordEvent(RLMEventContext *context, NSString *activity, NSString *event,
                         NSString *data, RLMEventCompletion completion) {
    auditContext(context)->record_event(activity.UTF8String, nsStringToOptionalString(event),
                                         nsStringToOptionalString(data), wrapCompletion(completion));
}

void RLMEventUpdateMetadata(RLMEventContext *context, NSDictionary<NSString *, NSString *> *newMetadata) {
    auditContext(context)->update_metadata(convertMetadata(newMetadata));
}

RLMEventContext *RLMEventGetContext(RLMRealm *realm) {
    return reinterpret_cast<RLMEventContext *>(realm->_realm->audit_context());
}

namespace {
class RLMEventSerializer : public realm::AuditObjectSerializer {
public:
    RLMEventSerializer(RLMRealmConfiguration *c) : _config(c.copy) {
        auto& config = _config.configRef;
        config.cache = false;
        config.audit_config = nullptr;
        config.automatic_change_notifications = false;
    }

    ~RLMEventSerializer() {
        scope_complete();
    }

    void scope_complete() final {
        for (auto& [_, acc] : _accessorMap) {
            if (acc) {
                acc->_realm = nil;
                acc->_objectSchema = nil;
            }
        }
        if (_realm) {
            _realm->_realm->close();
            _realm = nil;
        }
    }

    void to_json(nlohmann::json& out, const Obj& obj) final {
        @autoreleasepool {
            auto tableKey = obj.get_table()->get_key();
            RLMObjectBase *acc = getAccessor(tableKey);
            if (!acc) {
                return AuditObjectSerializer::to_json(out, obj);
            }

            if (!acc->_realm) {
                acc->_realm = realm();
                acc->_info = acc->_realm->_info[tableKey];
                acc->_objectSchema = acc->_info->rlmObjectSchema;
            }

            acc->_row = obj;
            RLMInitializeSwiftAccessor(acc, false);
            NSString *customRepresentation = [acc customEventRepresentation];
            out = nlohmann::json::parse(customRepresentation.UTF8String);
        }
    }

private:
    RLMRealmConfiguration *_config;
    RLMRealm *_realm;
    std::unordered_map<uint32_t, RLMObjectBase *> _accessorMap;

    RLMRealm *realm() {
        if (!_realm) {
            _realm = [RLMRealm realmWithConfiguration:_config error:nil];
        }
        return _realm;
    }

    RLMObjectBase *getAccessor(TableKey tableKey) {
        auto it = _accessorMap.find(tableKey.value);
        if (it != _accessorMap.end()) {
            return it->second;
        }

        RLMClassInfo *info = realm()->_info[tableKey];
        if (!info || !info->rlmObjectSchema.hasCustomEventSerialization) {
            _accessorMap.insert({tableKey.value, nil});
            return nil;
        }

        RLMObjectBase *acc = [[info->rlmObjectSchema.accessorClass alloc] init];
        acc->_realm = realm();
        acc->_objectSchema = info->rlmObjectSchema;
        acc->_info = info;
        _accessorMap.insert({tableKey.value, acc});
        return acc;
    }
};
} // anonymous namespace

@implementation RLMEventConfiguration
- (std::shared_ptr<AuditConfig>)auditConfigWithRealmConfiguration:(RLMRealmConfiguration *)realmConfig {
    auto config = std::make_shared<realm::AuditConfig>();
    config->audit_user = self.syncUser.user;
    config->partition_value_prefix = self.partitionPrefix.UTF8String;
    config->metadata = convertMetadata(self.metadata);
    config->serializer = std::make_shared<RLMEventSerializer>(realmConfig);
    if (_logger) {
        config->logger = RLMWrapLogFunction(_logger);
    }
    if (_errorHandler) {
        config->sync_error_handler = [eh = _errorHandler](realm::SyncError e) {
            if (auto error = makeError(std::move(e), nullptr)) {
                eh(error);
            }
        };
    }

    std::shared_ptr<realm::app::App> app;
    if (config->audit_user) {
        app = static_cast<realm::app::User&>(*config->audit_user).app();
    }
    else if (auto user = realmConfig.syncConfiguration.user) {
        app = user.user->app();
    }
    if (app) {
        config->base_file_path = app->config().base_file_path;
    }

    return config;
}
@end
