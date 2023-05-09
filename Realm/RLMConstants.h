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

#import <Foundation/Foundation.h>

#define RLM_HEADER_AUDIT_BEGIN NS_HEADER_AUDIT_BEGIN
#define RLM_HEADER_AUDIT_END NS_HEADER_AUDIT_END

#define RLM_SWIFT_SENDABLE NS_SWIFT_SENDABLE

#define RLM_FINAL __attribute__((objc_subclassing_restricted))

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

// Swift 5 considers NS_ENUM to be "open", meaning there could be values present
// other than the defined cases (which allows adding more cases later without
// it being a breaking change), while older versions consider it "closed".
#ifdef NS_CLOSED_ENUM
#define RLM_CLOSED_ENUM NS_CLOSED_ENUM
#else
#define RLM_CLOSED_ENUM NS_ENUM
#endif

#if __has_attribute(ns_error_domain) && (!defined(__cplusplus) || !__cplusplus || __cplusplus >= 201103L)
#define RLM_ERROR_ENUM(type, name, domain) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wignored-attributes\"") \
    NS_ENUM(type, __attribute__((ns_error_domain(domain))) name) \
    _Pragma("clang diagnostic pop")
#else
#define RLM_ERROR_ENUM(type, name, domain) NS_ENUM(type, name)
#endif

#define RLM_HIDDEN __attribute__((visibility("hidden")))
#define RLM_VISIBLE __attribute__((visibility("default")))
#define RLM_HIDDEN_BEGIN _Pragma("GCC visibility push(hidden)")
#define RLM_HIDDEN_END _Pragma("GCC visibility pop")
#define RLM_DIRECT __attribute__((objc_direct))
#define RLM_DIRECT_MEMBERS __attribute__((objc_direct_members))

#pragma mark - Enums

/**
 `RLMPropertyType` is an enumeration describing all property types supported in Realm models.

 For more information, see [Realm Models](https://www.mongodb.com/docs/realm/sdk/swift/fundamentals/object-models-and-schemas/).
 */
typedef RLM_CLOSED_ENUM(int32_t, RLMPropertyType) {

#pragma mark - Primitive types
    /** Integers: `NSInteger`, `int`, `long`, `Int` (Swift) */
    RLMPropertyTypeInt    = 0,
    /** Booleans: `BOOL`, `bool`, `Bool` (Swift) */
    RLMPropertyTypeBool   = 1,
    /** Floating-point numbers: `float`, `Float` (Swift) */
    RLMPropertyTypeFloat  = 5,
    /** Double-precision floating-point numbers: `double`, `Double` (Swift) */
    RLMPropertyTypeDouble = 6,
    /** NSUUID, UUID */
    RLMPropertyTypeUUID   = 12,

#pragma mark - Object types

    /** Strings: `NSString`, `String` (Swift) */
    RLMPropertyTypeString = 2,
    /** Binary data: `NSData` */
    RLMPropertyTypeData   = 3,
    /** Any type: `id<RLMValue>`, `AnyRealmValue` (Swift) */
    RLMPropertyTypeAny    = 9,
    /** Dates: `NSDate` */
    RLMPropertyTypeDate   = 4,

#pragma mark - Linked object types

    /** Realm model objects. See [Realm Models](https://www.mongodb.com/docs/realm/sdk/swift/fundamentals/object-models-and-schemas/) for more information. */
    RLMPropertyTypeObject = 7,
    /** Realm linking objects. See [Realm Models](https://www.mongodb.com/docs/realm/sdk/swift/fundamentals/relationships/#inverse-relationship) for more information. */
    RLMPropertyTypeLinkingObjects = 8,

    RLMPropertyTypeObjectId = 10,
    RLMPropertyTypeDecimal128 = 11
};

#pragma mark - Notification Constants

/**
 A notification indicating that changes were made to a Realm.
*/
typedef NSString * RLMNotification NS_EXTENSIBLE_STRING_ENUM;

/**
 This notification is posted when a write transaction has been committed to a Realm on a different thread for
 the same file.

 It is not posted if `autorefresh` is enabled, or if the Realm is refreshed before the notification has a chance
 to run.

 Realms with autorefresh disabled should normally install a handler for this notification which calls
 `-[RLMRealm refresh]` after doing some work. Refreshing the Realm is optional, but not refreshing the Realm may lead to
 large Realm files. This is because an extra copy of the data must be kept for the stale Realm.
 */
extern RLMNotification const RLMRealmRefreshRequiredNotification NS_SWIFT_NAME(RefreshRequired);

/**
 This notification is posted by a Realm when a write transaction has been
 committed to a Realm on a different thread for the same file.

 It is not posted if `-[RLMRealm autorefresh]` is enabled, or if the Realm is
 refreshed before the notification has a chance to run.

 Realms with autorefresh disabled should normally install a handler for this
 notification which calls `-[RLMRealm refresh]` after doing some work. Refreshing
 the Realm is optional, but not refreshing the Realm may lead to large Realm
 files. This is because Realm must keep an extra copy of the data for the stale
 Realm.
 */
extern RLMNotification const RLMRealmDidChangeNotification NS_SWIFT_NAME(DidChange);

#pragma mark - Error keys

/** Key to identify the associated backup Realm configuration in an error's `userInfo` dictionary */
extern NSString * const RLMBackupRealmConfigurationErrorKey;

#pragma mark - Other Constants

/** The schema version used for uninitialized Realms */
extern const uint64_t RLMNotVersioned;

/** The corresponding value is the name of an exception thrown by Realm. */
extern NSString * const RLMExceptionName;

/** The corresponding value is a Realm file version. */
extern NSString * const RLMRealmVersionKey;

/** The corresponding key is the version of the underlying database engine. */
extern NSString * const RLMRealmCoreVersionKey;

/** The corresponding key is the Realm invalidated property name. */
extern NSString * const RLMInvalidatedKey;

RLM_HEADER_AUDIT_END(nullability, sendability)
