////////////////////////////////////////////////////////////////////////////
//
// Copyright 2018 Realm Inc.
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

#import "RLMSyncSubscription.h"

#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.hpp"
#import "RLMProperty_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.hpp"
#import "RLMUtil.hpp"

#import "object_store.hpp"
#import "sync/partial_sync.hpp"

using namespace realm;

@implementation RLMSyncSubscriptionOptions
@end

@interface RLMSyncSubscription ()
@property (nonatomic, readwrite) RLMSyncSubscriptionState state;
@property (nonatomic, readwrite, nullable) NSError *error;
@property (nonatomic, readwrite) NSString *query;
@property (nonatomic, readwrite, nullable) NSDate *createdAt;
@property (nonatomic, readwrite, nullable) NSDate *updatedAt;
@property (nonatomic, readwrite, nullable) NSDate *expiresAt;
@property (nonatomic, readwrite) NSTimeInterval timeToLive;
@end

@implementation RLMSyncSubscription {
    partial_sync::SubscriptionNotificationToken _token;
    util::Optional<partial_sync::Subscription> _subscription;
    Object _obj;
    RLMRealm *_realm;
}

static std::vector<LinkPathPart> parseKeypath(StringData keypath, Group const& group,
                                              Schema const& schema, const ObjectSchema *objectSchema) {
    auto check = [&](bool condition, const char* fmt, auto... args) {
        if (!condition) {
            throw std::invalid_argument(util::format("Invalid LinkingObjects inclusion from key path '%1': %2.",
                                                     keypath, util::format(fmt, args...)));
        }
    };

    const char* begin = keypath.data();
    const char* end = keypath.data() + keypath.size();
    check(begin != end, "missing property name");

    std::vector<LinkPathPart> ret;
    while (begin != end) {
        auto sep = std::find(begin, end, '.');
        check(sep != begin && sep + 1 != end, "missing property name");
        StringData key(begin, sep - begin);
        begin = sep + (sep != end);

        auto prop = objectSchema->property_for_name(key);
        check(prop, "property '%1.%2' does not exist", objectSchema->name, key);
        check(prop->type == PropertyType::Object || prop->type == PropertyType::LinkingObjects,
              "property '%1.%2' is of unsupported type '%3'",
              objectSchema->name, key, string_for_property_type(prop->type));

        objectSchema = &*schema.find(prop->object_type);

        if (prop->type == PropertyType::Object) {
            check(begin != end, "key path must end in a LinkingObjects property and '%1.%2' is of type '%3'",
                  objectSchema->name, key, string_for_property_type(prop->type));
            ret.emplace_back(prop->table_column);
        }
        else {
            ret.emplace_back(objectSchema->property_for_name(prop->link_origin_property_name)->table_column,
                             ObjectStore::table_for_object_type(group, objectSchema->name));
        }
    }
    return ret;
}

- (instancetype)initWithOptions:(RLMSyncSubscriptionOptions *)options results:(Results const&)results realm:(RLMRealm *)realm {
    if (!(self = [super init]))
        return nil;

    _name = [options.name copy];
    _timeToLive = NAN;
    _realm = realm;
    _createdAt = _updatedAt = NSDate.date;
    try {
        partial_sync::SubscriptionOptions opt;
        if (options.name) {
            opt.user_provided_name = std::string(RLMStringDataWithNSString(options.name));
        }
        if (options.timeToLive > 0) {
            opt.time_to_live_ms = options.timeToLive * 1000;
        }
        opt.update = options.overwriteExisting;
        if (options.includeLinkingObjectProperties) {
            std::vector<std::vector<LinkPathPart>> keypaths;
            for (NSString *keyPath in options.includeLinkingObjectProperties) {
                keypaths.push_back(parseKeypath(keyPath.UTF8String, realm.group,
                                                realm->_realm->schema(),
                                                &results.get_object_schema()));
            }
            opt.inclusions = IncludeDescriptor{*ObjectStore::table_for_object_type(realm.group, results.get_object_type()), keypaths};
        }
        _subscription = partial_sync::subscribe(options.limit ? results.limit(options.limit) : results, std::move(opt));
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
    self.state = (RLMSyncSubscriptionState)_subscription->state();
    __weak auto weakSelf = self;
    _token = _subscription->add_notification_callback([weakSelf] {
        RLMSyncSubscription *self;
        @autoreleasepool {
            self = weakSelf;
            if (!self)
                return;
        }

        // Retrieve the current error and status. Update our properties only if the values have changed,
        // since clients use KVO to observe these properties.

        if (auto error = self->_subscription->error()) {
            try {
                std::rethrow_exception(error);
            } catch (...) {
                NSError *nsError;
                RLMRealmTranslateException(&nsError);
                if (!self.error || ![self.error isEqual:nsError])
                    self.error = nsError;
            }
        }
        else if (self.error) {
            self.error = nil;
        }

        auto status = (RLMSyncSubscriptionState)self->_subscription->state();
        if (status != self.state) {
            if (status == RLMSyncSubscriptionStateCreating) {
                // If a subscription is deleted without going through this
                // object's unsubscribe() method the subscription will transition
                // back to Creating rather than Invalidated since it doesn't
                // have a good way to track that it previously existed
                if (self.state != RLMSyncSubscriptionStateInvalidated)
                    self.state = RLMSyncSubscriptionStateInvalidated;
            }
            else {
                self.state = status;
            }
        }

        if (status != RLMSyncSubscriptionStateComplete) {
            return;
        }

        auto obj = self->_subscription->result_set_object();
        if (obj && obj->is_valid()) {
            _obj = std::move(*obj);
            _token = {};
            _token.result_sets_token = _obj.add_notification_callback([weakSelf](CollectionChangeSet const&, std::exception_ptr) {
                @autoreleasepool {
                    [weakSelf updateFromRow];
                }
            });
            [self updateFromRow];
        }
    });

    return self;
}

- (void)unsubscribe {
    partial_sync::unsubscribe(*_subscription);
}

- (void)updateFromRow {
    // We only want to call the setter if the value actually changed because of KVO
#define REALM_SET_IF_CHANGED(prop, value) do { \
    auto newValue = value; \
    if (prop != newValue) { \
        prop = newValue; \
    } \
} while (0)

    if (!_obj.is_valid()) {
        REALM_SET_IF_CHANGED(self.state, RLMSyncSubscriptionStateInvalidated);
        return;
    }

    auto row = _obj.row();
    REALM_SET_IF_CHANGED(self.query, RLMStringDataToNSString(row.get_string(row.get_column_index("query"))));
    REALM_SET_IF_CHANGED(self.createdAt, RLMTimestampToNSDate(row.get_timestamp(row.get_column_index("created_at"))));
    REALM_SET_IF_CHANGED(self.updatedAt, RLMTimestampToNSDate(row.get_timestamp(row.get_column_index("updated_at"))));
    REALM_SET_IF_CHANGED(self.expiresAt, RLMTimestampToNSDate(row.get_timestamp(row.get_column_index("expires_at"))));
#undef REALM_SET_IF_CHANGED

    auto ttl = row.get<util::Optional<int64_t>>(row.get_column_index("time_to_live"));
    if (ttl && _timeToLive != *ttl / 1000.0) {
        self.timeToLive = *ttl / 1000.0;
    }
    else if (!ttl && !isnan(_timeToLive)) {
        self.timeToLive = NAN;
    }
}
@end

@interface RLMSyncSubscriptionObject : RLMObjectBase
@end
@implementation RLMSyncSubscriptionObject {
    util::Optional<NotificationToken> _token;
    Object _obj;
}

+ (NSString *)primaryKey {
    return nil;
}

+ (NSDictionary *)defaultPropertyValues {
    return nil;
}

- (NSString *)name {
    return _row.is_attached() ? RLMStringDataToNSString(_row.get_string(_row.get_column_index("name"))) : nil;
}

- (NSString *)query {
    return _row.is_attached() ? RLMStringDataToNSString(_row.get_string(_row.get_column_index("query"))) : nil;
}

- (RLMSyncSubscriptionState)state {
    if (!_row.is_attached()) {
        return RLMSyncSubscriptionStateInvalidated;
    }
    return (RLMSyncSubscriptionState)_row.get_int(_row.get_column_index("status"));
}

- (NSError *)error {
    if (!_row.is_attached()) {
        return nil;
    }
    StringData err = _row.get_string(_row.get_column_index("error_message"));
    if (!err.size()) {
        return nil;
    }
    return [NSError errorWithDomain:RLMErrorDomain
                               code:RLMErrorFail
                           userInfo:@{NSLocalizedDescriptionKey: RLMStringDataToNSString(err)}];
}

- (NSDate *)createdAt {
    return _row.is_attached() ? RLMTimestampToNSDate(_row.get_timestamp(_row.get_column_index("created_at"))) : nil;
}

- (NSDate *)updatedAt {
    return _row.is_attached() ? RLMTimestampToNSDate(_row.get_timestamp(_row.get_column_index("updated_at"))) : nil;
}

- (NSDate *)expiresAt {
    return _row.is_attached() ? RLMTimestampToNSDate(_row.get_timestamp(_row.get_column_index("expires_at"))) : nil;
}

- (NSTimeInterval)timeToLive {
    if (!_row.is_attached()) {
        return NAN;
    }
    auto columnIndex = _row.get_column_index("time_to_live");
    if (_row.is_null(columnIndex)) {
        return NAN;
    }
    return _row.get_int(columnIndex) / 1000.0;
}

- (NSString *)descriptionWithMaxDepth:(NSUInteger)depth {
    if (depth == 0) {
        return @"<Maximum depth exceeded>";
    }

    auto objectType = _row.get_string(_row.get_column_index("matches_property"));
    objectType = objectType.substr(0, objectType.size() - strlen("_matches"));
    return [NSString stringWithFormat:@"RLMSyncSubscription {\n\tname = %@\n\tobjectType = %@\n\tquery = %@\n\tstatus = %@\n\terror = %@\n\tcreatedAt = %@\n\tupdatedAt = %@\n\texpiresAt = %@\n\ttimeToLive = %@\n}",
            self.name, RLMStringDataToNSString(objectType),
            RLMStringDataToNSString(_row.get_string(_row.get_column_index("query"))),
            @(self.state), self.error, self.createdAt, self.updatedAt, self.expiresAt, @(self.timeToLive)];
}

- (void)unsubscribe {
    if (_row) {
        partial_sync::unsubscribe(Object(_realm->_realm, *_info->objectSchema, _row));
    }
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    // Make the `state` property observable by using an object notifier to
    // trigger changes. The normal KVO mechanisms don't work for this class due
    // to it not being a normal part of the schema.
    if (!_token) {
        struct {
            __weak RLMSyncSubscriptionObject *weakSelf;

            void before(realm::CollectionChangeSet const&) {
                @autoreleasepool {
                    [weakSelf willChangeValueForKey:@"state"];
                }
            }

            void after(realm::CollectionChangeSet const&) {
                @autoreleasepool {
                    [weakSelf didChangeValueForKey:@"state"];
                }
            }

            void error(std::exception_ptr) {}
        } callback{self};
        _obj = Object(_realm->_realm, *_info->objectSchema, _row);
        _token = _obj.add_notification_callback(callback);
    }
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}
@end

static ObjectSchema& addPublicNames(ObjectSchema& os) {
    using namespace partial_sync;
    os.property_for_name(property_created_at)->public_name    = "createdAt";
    os.property_for_name(property_updated_at)->public_name    = "updatedAt";
    os.property_for_name(property_expires_at)->public_name    = "expiresAt";
    os.property_for_name(property_time_to_live)->public_name  = "timeToLive";
    os.property_for_name(property_error_message)->public_name = "error";
    return os;
}

// RLMClassInfo stores pointers into the schema rather than owning the objects
// it points to, so for a ClassInfo that's not part of the schema we need a
// wrapper object that owns them
RLMResultsSetInfo::RLMResultsSetInfo(__unsafe_unretained RLMRealm *const realm)
: osObjectSchema(realm->_realm->read_group(), partial_sync::result_sets_type_name)
, rlmObjectSchema([RLMObjectSchema objectSchemaForObjectStoreSchema:addPublicNames(osObjectSchema)])
, info(realm, rlmObjectSchema, &osObjectSchema)
{
    rlmObjectSchema.accessorClass = [RLMSyncSubscriptionObject class];
}

RLMClassInfo& RLMResultsSetInfo::get(__unsafe_unretained RLMRealm *const realm) {
    if (!realm->_resultsSetInfo) {
        realm->_resultsSetInfo = std::make_unique<RLMResultsSetInfo>(realm);
    }
    return realm->_resultsSetInfo->info;
}

@interface RLMSubscriptionResults : RLMResults
@end

@implementation RLMSubscriptionResults
+ (instancetype)resultsWithRealm:(RLMRealm *)realm {
    auto table = ObjectStore::table_for_object_type(realm->_realm->read_group(), partial_sync::result_sets_type_name);
    if (!table) {
        @throw RLMException(@"-[RLMRealm subscriptions] can only be called on a Realm using query-based sync");
    }
    // The server automatically adds a few subscriptions for the permissions
    // types which we want to hide. They're just an implementation detail and
    // deleting them won't work out well for the user.
    auto query = table->where().ends_with(table->get_column_index("matches_property"), "_matches");
    return [self resultsWithObjectInfo:RLMResultsSetInfo::get(realm)
                               results:Results(realm->_realm, std::move(query))];
}

// These operations require a valid schema for the type. It's unclear how they
// would be useful so it's probably not worth fixing this.
- (RLMResults *)sortedResultsUsingDescriptors:(__unused NSArray<RLMSortDescriptor *> *)properties {
    @throw RLMException(@"Sorting subscription results is currently not implemented");
}

- (RLMResults *)distinctResultsUsingKeyPaths:(__unused NSArray<NSString *> *)keyPaths {
    @throw RLMException(@"Distincting subscription results is currently not implemented");
}
@end

@implementation RLMResults (SyncSubscription)
- (RLMSyncSubscription *)subscribe {
    return [[RLMSyncSubscription alloc] initWithOptions:nil results:_results realm:self.realm];
}

- (RLMSyncSubscription *)subscribeWithName:(NSString *)subscriptionName {
    auto options = [[RLMSyncSubscriptionOptions alloc] init];
    options.name = subscriptionName;
    return [[RLMSyncSubscription alloc] initWithOptions:options results:_results realm:self.realm];
}

- (RLMSyncSubscription *)subscribeWithName:(NSString *)subscriptionName limit:(NSUInteger)limit {
    auto options = [[RLMSyncSubscriptionOptions alloc] init];
    options.name = subscriptionName;
    options.limit = limit;
    return [[RLMSyncSubscription alloc] initWithOptions:options results:_results realm:self.realm];
}

- (RLMSyncSubscription *)subscribeWithOptions:(RLMSyncSubscriptionOptions *)options {
    return [[RLMSyncSubscription alloc] initWithOptions:options results:_results realm:self.realm];
}
@end

@implementation RLMRealm (SyncSubscription)
- (RLMResults<RLMSyncSubscription *> *)subscriptions {
    [self verifyThread];
    return [RLMSubscriptionResults resultsWithRealm:self];
}

- (nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name {
    [self verifyThread];
    auto& info = RLMResultsSetInfo::get(self);
    if (!info.table()) {
        @throw RLMException(@"-[RLMRealm subcriptionWithName:] can only be called on a Realm using query-based sync");
    }
    auto row = info.table()->find_first(info.table()->get_column_index("name"),
                                        RLMStringDataWithNSString(name));
    if (row == npos) {
        return nil;
    }
    RLMObjectBase *acc = RLMCreateManagedAccessor(info.rlmObjectSchema.accessorClass, &info);
    acc->_row = info.table()->get(row);
    return (RLMSyncSubscription *)acc;
}
@end

RLMSyncSubscription *RLMCastToSyncSubscription(id obj) {
    return obj;
}
