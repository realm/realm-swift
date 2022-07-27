////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMAccessor.h"

#import "RLMClassInfo.hpp"
#import "RLMDecimal128_Private.hpp"
#import "RLMObjectId_Private.hpp"
#import "RLMUUID_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/object_accessor.hpp>

@class RLMRealm;
class RLMClassInfo;
class RLMObservationTracker;
typedef NS_ENUM(NSUInteger, RLMUpdatePolicy);

// std::optional<id> doesn't work because Objective-C types can't
// be members of unions with ARC, so this covers the subset of Optional that we
// actually need.
struct RLMOptionalId {
    id value;
    RLMOptionalId(id value) : value(value) { }
    explicit operator bool() const noexcept { return value; }
    id operator*() const noexcept { return value; }
};

// The subset of RLMAccessorContext which does not require any member variables.
// Use this if you require to box/unbox types and you do not have access to the
// parent object or realm.
struct RLMStatelessAccessorContext {
    static id box(bool v) { return @(v); }
    static id box(double v) { return @(v); }
    static id box(float v) { return @(v); }
    static id box(long long v) { return @(v); }
    static id box(realm::StringData v) { return RLMStringDataToNSString(v) ?: NSNull.null; }
    static id box(realm::BinaryData v) { return RLMBinaryDataToNSData(v) ?: NSNull.null; }
    static id box(realm::Timestamp v) { return RLMTimestampToNSDate(v) ?: NSNull.null; }
    static id box(realm::Decimal128 v) { return v.is_null() ? NSNull.null : [[RLMDecimal128 alloc] initWithDecimal128:v]; }
    static id box(realm::ObjectId v) { return [[RLMObjectId alloc] initWithValue:v]; }
    static id box(realm::UUID v) { return [[NSUUID alloc] initWithRealmUUID:v]; }

    static id box(std::optional<bool> v) { return v ? @(*v) : NSNull.null; }
    static id box(std::optional<double> v) { return v ? @(*v) : NSNull.null; }
    static id box(std::optional<float> v) { return v ? @(*v) : NSNull.null; }
    static id box(std::optional<int64_t> v) { return v ? @(*v) : NSNull.null; }
    static id box(std::optional<realm::ObjectId> v) { return v ? box(*v) : NSNull.null; }
    static id box(std::optional<realm::UUID> v) { return v ? box(*v) : NSNull.null; }

    template<typename T>
    static T unbox(id v);

    template<typename Func>
    static void enumerate_collection(__unsafe_unretained const id v, Func&& func) {
        id enumerable = RLMAsFastEnumeration(v) ?: v;
        for (id value in enumerable) {
            func(value);
        }
    }

    template<typename Func>
    static void enumerate_dictionary(__unsafe_unretained const id v, Func&& func) {
        id enumerable = RLMAsFastEnumeration(v) ?: v;
        for (id key in enumerable) {
            func(unbox<realm::StringData>(key), v[key]);
        }
    }

    static bool is_null(id v) noexcept { return v == NSNull.null; }
    static id null_value() noexcept { return NSNull.null; }
    static id no_value() noexcept { return nil; }
    static bool allow_missing(id v) noexcept { return [v isKindOfClass:[NSArray class]]; }

    static bool is_same_list(realm::List const& list, id v) noexcept;
    static bool is_same_dictionary(realm::object_store::Dictionary const&, id) noexcept;
    static bool is_same_set(realm::object_store::Set const&, id) noexcept;

    static std::string print(id obj) { return [obj description].UTF8String; }
};

class RLMAccessorContext : public RLMStatelessAccessorContext {
public:
    ~RLMAccessorContext();

    // Accessor context interface
    RLMAccessorContext(RLMAccessorContext& parent, realm::Obj const& parent_obj, realm::Property const& property);

    using RLMStatelessAccessorContext::box;
    id box(realm::List&&);
    id box(realm::Results&&);
    id box(realm::Object&&);
    id box(realm::Obj&&);
    id box(realm::object_store::Dictionary&&);
    id box(realm::object_store::Set&&);
    id box(realm::Mixed);

    void will_change(realm::Obj const&, realm::Property const&);
    void will_change(realm::Object& obj, realm::Property const& prop) { will_change(obj.obj(), prop); }
    void did_change();

    RLMOptionalId value_for_property(id dict, realm::Property const&, size_t prop_index);
    RLMOptionalId default_value_for_property(realm::ObjectSchema const&,
                                             realm::Property const& prop);

    template<typename T>
    T unbox(__unsafe_unretained id const v, realm::CreatePolicy = realm::CreatePolicy::Skip, realm::ObjKey = {}) {
        return RLMStatelessAccessorContext::unbox<T>(v);
    }
    template<>
    realm::Obj unbox(id v, realm::CreatePolicy, realm::ObjKey);
    template<>
    realm::Mixed unbox(id v, realm::CreatePolicy, realm::ObjKey);

    realm::Obj create_embedded_object();

    // Internal API
    RLMAccessorContext(RLMObjectBase *parentObject, const realm::Property *property = nullptr);
    RLMAccessorContext(RLMObjectBase *parentObject, realm::ColKey);
    RLMAccessorContext(RLMClassInfo& info);

    // The property currently being accessed; needed for KVO things for boxing
    // List and Results
    RLMProperty *currentProperty;

    std::pair<realm::Obj, bool>
    createObject(id value, realm::CreatePolicy policy, bool forceCreate=false, realm::ObjKey existingKey={});

private:
    __unsafe_unretained RLMRealm *const _realm;
    RLMClassInfo& _info;

    realm::Obj _parentObject;
    RLMClassInfo* _parentObjectInfo = nullptr;
    realm::ColKey _colKey;

    // Cached default values dictionary to avoid having to call the class method
    // for every property
    NSDictionary *_defaultValues;

    std::unique_ptr<RLMObservationTracker> _observationHelper;

    id defaultValue(NSString *key);
    id propertyValue(id obj, size_t propIndex, __unsafe_unretained RLMProperty *const prop);
};
