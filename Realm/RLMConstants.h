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

/**
 Attributes which can be returned when implementing attributesForProperty:
 */

typedef NS_OPTIONS(NSUInteger, RLMPropertyAttributes) {
/**
 Create an index for this property for improved search performance. Only string properties
 can be indexed. Returning this for properties of any other type will have no effect.
 */
    RLMPropertyAttributeIndexed = 1 << 2,

/**
 Store this property inline (de-normalization) which in some cases can improve performance. Setting this
 attribute will result in objects being copied (rather than linked) when setting this property.
 */
//    RLMPropertyAttributeInlined = 1 << 3,

/**
 The value for a property with this attribute must be unique across all objects of this type. An exception
 will be thrown when setting a property with this attribute to a non-unique value.
 */
//    RLMPropertyAttributeUnique = 1 << 4,

/**
 This property value must be set before the object can be added to a Realm. If not set an
 exception will be thrown if no default value for this property is specified. If a default
 value is specified it is set upon insertion into a Realm

 @see [RLMObject defaultPropertyValues]
 */
//    RLMPropertyAttributeRequired = 1 << 5,

/**
 When a parent object is deleted or a child property is nullified nothing is done.
 This is the default delete rule.

 Set this attribute on RLMPropertyTypeObject or RLMPropertyTypeArray properties
 to customize the properties’ delete rule. This rule is mutually exclusive with
 `RLMPropertyAttributeDeleteIfOnlyOwner` and `RLMPropertyAttributeDeleteAlways`.
 */
//    RLMPropertyAttributeDeleteNever = 0,

/**
 Delete a child object (or object in an RLMArray) when the parent is deleted or the object is
 nullified only if no other objects in the realm reference the object.

 Set this attribute on RLMPropertyTypeObject or RLMPropertyTypeArray properties
 to customize the properties’ delete rule. This rule is mutually exclusive with
 `RLMPropertyAttributeDeleteNever` and `RLMPropertyAttributeDeleteAlways`.
 */
//    RLMPropertyAttributeDeleteIfOnlyOwner = 1 << 0,

/**
 Always delete a child object or object in a child array when the parent is deleted or the
 reference in nullified. If other objects reference the same child object those references are
 nullified.

 Set this attribute on RLMPropertyTypeObject or RLMPropertyTypeArray properties
 to customize the properties’ delete rule. This rule is mutually exclusive with
 `RLMPropertyAttributeDeleteNever` and `RLMPropertyAttributeDeleteIfOnlyOwner`.
 */
//    RLMPropertyAttributeDeleteAlways = 1 << 1
};

/**
 Property types supported in Realm models.

 See [Realm Models](http://realm.io/docs/cocoa/latest/#models)
 */
// Make sure numbers match those in <tightdb/data_type.hpp>
typedef NS_ENUM(int32_t, RLMPropertyType) {
    ////////////////////////////////
    // Primitive types
    ////////////////////////////////

    /** Integer type: NSInteger, int, long, Int (Swift) */
    RLMPropertyTypeInt    = 0,
    /** Boolean type: BOOL, bool, Bool (Swift) */
    RLMPropertyTypeBool   = 1,
    /** Float type: CGFloat (32bit), float, Float (Swift) */
    RLMPropertyTypeFloat  = 9,
    /** Double type: CGFloat (64bit), double, Double (Swift) */
    RLMPropertyTypeDouble = 10,

    ////////////////////////////////
    // Object types
    ////////////////////////////////

    /** String type: NSString, String (Swift) */
    RLMPropertyTypeString = 2,
    /** Data type: NSData */
    RLMPropertyTypeData   = 4,
    /** Any type: id, **not supported in Swift** */
    RLMPropertyTypeAny    = 6,
    /** Date type: NSDate */
    RLMPropertyTypeDate   = 7,

    ////////////////////////////////
    // Array/Linked object types
    ////////////////////////////////

    /** Object type. See [Realm Models](http://realm.io/docs/cocoa/latest/#models) */
    RLMPropertyTypeObject = 12,
    /** Array type. See [Realm Models](http://realm.io/docs/cocoa/latest/#models) */
    RLMPropertyTypeArray  = 13,
};

// Appledoc doesn't support documenting externed globals, so document them as an
// enum instead
#ifdef APPLEDOC
typedef NS_ENUM(NSString, RLMRealmNotification) {
/**
 Posted by RLMRealm when the data in the realm has changed.

 DidChange are posted after a realm has been refreshed to reflect a write
 transaction, i.e. when an autorefresh occurs, [refresh]([RLMRealm refresh]) is
 called, after an implicit refresh from [beginWriteTransaction]([RLMRealm beginWriteTransaction]),
 and after a local write transaction is committed.
 */
    RLMRealmDidChangeNotification,
/**
 Posted by RLMRealm when a write transaction has been committed to a RLMRealm on
 a different thread for the same file. This is not posted if
 [autorefresh]([RLMRealm autorefresh]) is enabled or if the RLMRealm is
 refreshed before the notifcation has a chance to run.

 Realms with autorefresh disabled should normally have a handler for this
 notification which calls [refresh]([RLMRealm refresh]) after doing some work.
 While not refreshing is allowed, it may lead to large Realm files as Realm has
 to keep an extra copy of the data for the un-refreshed RLMRealm.
 */
    RLMRealmRefreshRequiredNotification,
};
#else
// See comments above
extern NSString * const RLMRealmRefreshRequiredNotification;
extern NSString * const RLMRealmDidChangeNotification;
#endif

typedef NS_ENUM(NSInteger, RLMError) {
    /** Retuned by RLMRealm if no other specific error is returned when a realm is opened. */
    RLMErrorFail                  = 1,
    /** Returned by RLMRealm for any I/O related exception scenarios when a realm is opened. */
    RLMErrorFileAccessError       = 2,
    /** Returned by RLMRealm if the user does not have permission to open or create
        the specified file in the specified access mode when the realm is opened. */
    RLMErrorFilePermissionDenied  = 3,
    /** Returned by RLMRealm if no_create was specified and the file did already exist when the realm is opened. */
    RLMErrorFileExists            = 4,
    /** Returned by RLMRealm if no_create was specified and the file was not found when the realm is opened. */
    RLMErrorFileNotFound          = 5,
    /** Returned by RLMRealm if a stale .lock file is present when the realm is opened. */
    RLMErrorStaleLockFile         = 6,
    /** Returned by RLMRealm if the database file is deleted while there are open realms,
        and subsequent attempts to open realms will try to join an already
        active shared scheme, but fail due to the missing database file. */
    RLMErrorLockFileButNoData     = 7
};
