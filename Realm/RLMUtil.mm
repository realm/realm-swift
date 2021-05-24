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

#import "RLMUtil.hpp"

#import "RLMArray_Private.hpp"
#import "RLMAccessor.hpp"
#import "RLMDecimal128_Private.hpp"
#import "RLMDictionary_Private.h"
#import "RLMObjectId_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMSwiftValueStorage.h"
#import "RLMSchema_Private.h"
#import "RLMSet_Private.hpp"
#import "RLMSwiftCollectionBase.h"
#import "RLMSwiftSupport.h"
#import "RLMUUID_Private.hpp"
#import "RLMValue.h"

#import <realm/mixed.hpp>
#import <realm/object-store/shared_realm.hpp>
#import <realm/table_view.hpp>
#import <realm/util/overload.hpp>

#if REALM_ENABLE_SYNC
#import "RLMSyncUtil.h"
#import <realm/sync/client.hpp>
#endif

#include <sys/sysctl.h>
#include <sys/types.h>

#if !defined(REALM_COCOA_VERSION)
#import "RLMVersion.h"
#endif

static inline RLMArray *asRLMArray(__unsafe_unretained id const value) {
    return RLMDynamicCast<RLMArray>(value) ?: RLMDynamicCast<RLMSwiftCollectionBase>(value)._rlmCollection;
}

static inline RLMSet *asRLMSet(__unsafe_unretained id const value) {
    return RLMDynamicCast<RLMSet>(value) ?: RLMDynamicCast<RLMSwiftCollectionBase>(value)._rlmCollection;
}

static inline RLMDictionary *asRLMDictionary(__unsafe_unretained id const value) {
    return RLMDynamicCast<RLMDictionary>(value) ?: RLMDynamicCast<RLMSwiftCollectionBase>(value)._rlmCollection;
}

static inline bool checkCollectionType(__unsafe_unretained id<RLMCollection> const collection,
                                  RLMPropertyType type,
                                  bool optional,
                                  __unsafe_unretained NSString *const objectClassName) {
    return collection.type == type && collection.optional == optional
        && (type != RLMPropertyTypeObject || [collection.objectClassName isEqualToString:objectClassName]);
}

id (*RLMSwiftAsFastEnumeration)(id);
id<NSFastEnumeration> RLMAsFastEnumeration(__unsafe_unretained id obj) {
    if (!obj) {
        return nil;
    }
    if ([obj conformsToProtocol:@protocol(NSFastEnumeration)]) {
        return obj;
    }
    if (RLMSwiftAsFastEnumeration) {
        return RLMSwiftAsFastEnumeration(obj);
    }
    return nil;
}

bool RLMIsSwiftObjectClass(Class cls) {
    static Class s_swiftObjectClass = NSClassFromString(@"RealmSwiftObject");
    static Class s_swiftEmbeddedObjectClass = NSClassFromString(@"RealmSwiftEmbeddedObject");
    return [cls isSubclassOfClass:s_swiftObjectClass] || [cls isSubclassOfClass:s_swiftEmbeddedObjectClass];
}

BOOL RLMValidateValue(__unsafe_unretained id const value,
                      RLMPropertyType type,
                      bool optional,
                      bool collection,
                      __unsafe_unretained NSString *const objectClassName) {
    if (optional && !RLMCoerceToNil(value)) {
        return YES;
    }

    if (collection) {
        if (auto rlmArray = asRLMArray(value)) {
            return checkCollectionType(rlmArray, type, optional, objectClassName);
        }
        else if (auto rlmSet = asRLMSet(value)) {
            return checkCollectionType(rlmSet, type, optional, objectClassName);
        }
        else if (auto rlmDictionary = asRLMDictionary(value)) {
            return checkCollectionType(rlmDictionary, type, optional, objectClassName);
        }
        if (id enumeration = RLMAsFastEnumeration(value)) {
            // check each element for compliance
            for (id el in enumeration) {
                if (!RLMValidateValue(el, type, optional, false, objectClassName)) {
                    return NO;
                }
            }
            return YES;
        }
        if (!value || value == NSNull.null) {
            return YES;
        }
        return NO;
    }

    switch (type) {
        case RLMPropertyTypeString:
            return [value isKindOfClass:[NSString class]];
        case RLMPropertyTypeBool:
            if ([value isKindOfClass:[NSNumber class]]) {
                return numberIsBool(value);
            }
            return NO;
        case RLMPropertyTypeDate:
            return [value isKindOfClass:[NSDate class]];
        case RLMPropertyTypeInt:
            if (NSNumber *number = RLMDynamicCast<NSNumber>(value)) {
                return numberIsInteger(number);
            }
            return NO;
        case RLMPropertyTypeFloat:
            if (NSNumber *number = RLMDynamicCast<NSNumber>(value)) {
                return numberIsFloat(number);
            }
            return NO;
        case RLMPropertyTypeDouble:
            if (NSNumber *number = RLMDynamicCast<NSNumber>(value)) {
                return numberIsDouble(number);
            }
            return NO;
        case RLMPropertyTypeData:
            return [value isKindOfClass:[NSData class]];
        case RLMPropertyTypeAny: {
            return !value
                || [value conformsToProtocol:@protocol(RLMValue)];
        }
        case RLMPropertyTypeLinkingObjects:
            return YES;
        case RLMPropertyTypeObject: {
            // only NSNull, nil, or objects which derive from RLMObject and match the given
            // object class are valid
            RLMObjectBase *objBase = RLMDynamicCast<RLMObjectBase>(value);
            return objBase && [objBase->_objectSchema.className isEqualToString:objectClassName];
        }
        case RLMPropertyTypeObjectId:
            return [value isKindOfClass:[RLMObjectId class]];
        case RLMPropertyTypeDecimal128:
            return [value isKindOfClass:[NSNumber class]]
                || [value isKindOfClass:[RLMDecimal128 class]]
                || ([value isKindOfClass:[NSString class]] && realm::Decimal128::is_valid_str([value UTF8String]));
        case RLMPropertyTypeUUID:
            return [value isKindOfClass:[NSUUID class]]
                || ([value isKindOfClass:[NSString class]] && realm::UUID::is_valid_string([value UTF8String]));
    }
    @throw RLMException(@"Invalid RLMPropertyType specified");
}

void RLMThrowTypeError(__unsafe_unretained id const obj,
                       __unsafe_unretained RLMObjectSchema *const objectSchema,
                       __unsafe_unretained RLMProperty *const prop) {
    @throw RLMException(@"Invalid value '%@' of type '%@' for '%@%s'%s property '%@.%@'.",
                        obj, [obj class],
                        prop.objectClassName ?: RLMTypeToString(prop.type), prop.optional ? "?" : "",
                        prop.array ? " array" : prop.set ? " set" : prop.dictionary ? " dictionary" : "", objectSchema.className, prop.name);
}

void RLMValidateValueForProperty(__unsafe_unretained id const obj,
                                 __unsafe_unretained RLMObjectSchema *const objectSchema,
                                 __unsafe_unretained RLMProperty *const prop,
                                 bool validateObjects) {
    // This duplicates a lot of the checks in RLMIsObjectValidForProperty()
    // for the sake of more specific error messages
    if (prop.collection) {
        // nil is considered equivalent to an empty array for historical reasons
        // since we don't support null arrays (only arrays containing null),
        // it's not worth the BC break to change this
        if (!obj || obj == NSNull.null) {
            return;
        }
        id enumeration = RLMAsFastEnumeration(obj);
        if (!enumeration) {
            @throw RLMException(@"Invalid value (%@) for '%@%s' %@ property '%@.%@': value is not enumerable.",
                                obj,
                                prop.objectClassName ?: RLMTypeToString(prop.type),
                                prop.optional ? "?" : "",
                                prop.array ? @"array" : @"set",
                                objectSchema.className, prop.name);
        }
        if (!validateObjects && prop.type == RLMPropertyTypeObject) {
            return;
        }

        if (RLMArray *array = asRLMArray(obj)) {
            if (!checkCollectionType(array, prop.type, prop.optional, prop.objectClassName)) {
                @throw RLMException(@"RLMArray<%@%s> does not match expected type '%@%s' for property '%@.%@'.",
                                    array.objectClassName ?: RLMTypeToString(array.type), array.optional ? "?" : "",
                                    prop.objectClassName ?: RLMTypeToString(prop.type), prop.optional ? "?" : "",
                                    objectSchema.className, prop.name);
            }
            return;
        }
        else if (RLMSet *set = asRLMSet(obj)) {
            if (!checkCollectionType(set, prop.type, prop.optional, prop.objectClassName)) {
                @throw RLMException(@"RLMSet<%@%s> does not match expected type '%@%s' for property '%@.%@'.",
                                    set.objectClassName ?: RLMTypeToString(set.type), set.optional ? "?" : "",
                                    prop.objectClassName ?: RLMTypeToString(prop.type), prop.optional ? "?" : "",
                                    objectSchema.className, prop.name);
            }
            return;
        }
        else if (RLMDictionary *dictionary = asRLMDictionary(obj)) {
            if (!checkCollectionType(dictionary, prop.type, prop.optional, prop.objectClassName)) {
                @throw RLMException(@"RLMDictionary<%@, %@%s> does not match expected type '%@%s' for property '%@.%@'.",
                                    RLMTypeToString(dictionary.keyType),
                                    dictionary.objectClassName ?: RLMTypeToString(dictionary.type), dictionary.optional ? "?" : "",
                                    prop.objectClassName ?: RLMTypeToString(prop.type), prop.optional ? "?" : "",
                                    objectSchema.className, prop.name);
            }
            return;
        }

        if (prop.dictionary) {
            for (id key in enumeration) {
                id value = enumeration[key];
                if (!RLMValidateValue(value, prop.type, prop.optional, false, prop.objectClassName)) {
                    RLMThrowTypeError(value, objectSchema, prop);
                }
            }
        }
        else {
            for (id value in enumeration) {
                if (!RLMValidateValue(value, prop.type, prop.optional, false, prop.objectClassName)) {
                    RLMThrowTypeError(value, objectSchema, prop);
                }
            }
        }
        return;
    }

    // For create() we want to skip the validation logic for objects because
    // we allow much fuzzier matching (any KVC-compatible object with at least
    // all the non-defaulted fields), and all the logic for that lives in the
    // object store rather than here
    if (prop.type == RLMPropertyTypeObject && !validateObjects) {
        return;
    }
    if (RLMIsObjectValidForProperty(obj, prop)) {
        return;
    }

    RLMThrowTypeError(obj, objectSchema, prop);
}

BOOL RLMIsObjectValidForProperty(__unsafe_unretained id const obj,
                                 __unsafe_unretained RLMProperty *const property) {
    return RLMValidateValue(obj,
                            property.type,
                            property.optional,
                            property.collection,
                            property.objectClassName);
}

NSDictionary *RLMDefaultValuesForObjectSchema(__unsafe_unretained RLMObjectSchema *const objectSchema) {
    if (!objectSchema.isSwiftClass) {
        return [objectSchema.objectClass defaultPropertyValues];
    }

    NSMutableDictionary *defaults = nil;
    if ([objectSchema.objectClass isSubclassOfClass:RLMObject.class]) {
        defaults = [NSMutableDictionary dictionaryWithDictionary:[objectSchema.objectClass defaultPropertyValues]];
    }
    else {
        defaults = [NSMutableDictionary dictionary];
    }
    RLMObject *defaultObject = [[objectSchema.objectClass alloc] init];
    for (RLMProperty *prop in objectSchema.properties) {
        if (!defaults[prop.name] && defaultObject[prop.name]) {
            defaults[prop.name] = defaultObject[prop.name];
        }
    }
    return defaults;
}

static NSException *RLMException(NSString *reason, NSDictionary *additionalUserInfo) {
    NSMutableDictionary *userInfo = @{RLMRealmVersionKey: REALM_COCOA_VERSION,
                                      RLMRealmCoreVersionKey: @REALM_VERSION}.mutableCopy;
    if (additionalUserInfo != nil) {
        [userInfo addEntriesFromDictionary:additionalUserInfo];
    }
    NSException *e = [NSException exceptionWithName:RLMExceptionName
                                             reason:reason
                                           userInfo:userInfo];
    return e;
}

NSException *RLMException(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSException *e = RLMException([[NSString alloc] initWithFormat:fmt arguments:args], @{});
    va_end(args);
    return e;
}

NSException *RLMException(std::exception const& exception) {
    return RLMException(@"%s", exception.what());
}

NSError *RLMMakeError(RLMError code, std::exception const& exception) {
    return [NSError errorWithDomain:RLMErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      @"Error Code": @(code)}];
}

NSError *RLMMakeError(RLMError code, const realm::util::File::AccessError& exception) {
    return [NSError errorWithDomain:RLMErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      NSFilePathErrorKey: @(exception.get_path().c_str()),
                                      @"Error Code": @(code)}];
}

NSError *RLMMakeError(RLMError code, const realm::RealmFileException& exception) {
    NSString *underlying = @(exception.underlying().c_str());
    return [NSError errorWithDomain:RLMErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      NSFilePathErrorKey: @(exception.path().c_str()),
                                      @"Error Code": @(code),
                                      @"Underlying": underlying.length == 0 ? @"n/a" : underlying}];
}

NSError *RLMMakeError(std::system_error const& exception) {
    int code = exception.code().value();
    BOOL isGenericCategoryError = (exception.code().category() == std::generic_category());
    NSString *category = @(exception.code().category().name());
    NSString *errorDomain = isGenericCategoryError ? NSPOSIXErrorDomain : RLMUnknownSystemErrorDomain;
#if REALM_ENABLE_SYNC
    if (exception.code().category() == realm::sync::client_error_category()) {
        if (exception.code().value() == static_cast<int>(realm::sync::Client::Error::connect_timeout)) {
            errorDomain = NSPOSIXErrorDomain;
            code = ETIMEDOUT;
        }
        else {
            errorDomain = RLMSyncErrorDomain;
        }
    }
#endif

    return [NSError errorWithDomain:errorDomain code:code
                           userInfo:@{NSLocalizedDescriptionKey: @(exception.what()),
                                      @"Error Code": @(exception.code().value()),
                                      @"Category": category}];
}

void RLMSetErrorOrThrow(NSError *error, NSError **outError) {
    if (outError) {
        *outError = error;
    }
    else {
        NSString *msg = error.localizedDescription;
        if (error.userInfo[NSFilePathErrorKey]) {
            msg = [NSString stringWithFormat:@"%@: %@", error.userInfo[NSFilePathErrorKey], error.localizedDescription];
        }
        @throw RLMException(msg, @{NSUnderlyingErrorKey: error});
    }
}

BOOL RLMIsDebuggerAttached()
{
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

BOOL RLMIsRunningInPlayground() {
    return [[NSBundle mainBundle].bundleIdentifier hasPrefix:@"com.apple.dt.playground."];
}

realm::Mixed RLMObjcToMixed(__unsafe_unretained id v,
                            __unsafe_unretained RLMRealm *realm,
                            realm::CreatePolicy createPolicy) {
    if (!v || v == NSNull.null) {
        return realm::Mixed();
    }

    REALM_ASSERT([v conformsToProtocol:@protocol(RLMValue)]);
    RLMPropertyType type = [v rlm_valueType];
    return switch_on_type(static_cast<realm::PropertyType>(type), realm::util::overload{[&](realm::Obj*) {
        // The RLMObjectBase may be unmanaged and therefor has no RLMClassInfo attached.
        // So we fetch from the Realm instead.
        // If the Object is managed use it's RLMClassInfo instead so we do not have to do a
        // lookup in the table of schemas.
        RLMObjectBase *objBase = v;
        RLMAccessorContext c{objBase->_info ? *objBase->_info : realm->_info[objBase->_objectSchema.className]};
        auto obj = c.unbox<realm::Obj>(v, createPolicy);
        return obj.is_valid() ? realm::Mixed(obj) : realm::Mixed();
    }, [&](auto t) {
        RLMStatelessAccessorContext c;
        return realm::Mixed(c.unbox<std::decay_t<decltype(*t)>>(v));
    }, [&](realm::Mixed*) {
        REALM_UNREACHABLE();
        return realm::Mixed();
    }});
}

id RLMMixedToObjc(realm::Mixed const& mixed,
                  __unsafe_unretained RLMRealm *realm,
                  RLMClassInfo *classInfo) {
    if (mixed.is_null()) {
        return NSNull.null;
    }
    switch (mixed.get_type()) {
        case realm::type_String:
            return RLMStringDataToNSString(mixed.get_string());
        case realm::type_Int:
            return @(mixed.get_int());
        case realm::type_Float:
            return @(mixed.get_float());
        case realm::type_Double:
            return @(mixed.get_double());
        case realm::type_Bool:
            return @(mixed.get_bool());
        case realm::type_Timestamp:
            return RLMTimestampToNSDate(mixed.get_timestamp());
        case realm::type_Binary:
            return RLMBinaryDataToNSData(mixed.get<realm::BinaryData>());
        case realm::type_Decimal:
            return [[RLMDecimal128 alloc] initWithDecimal128:mixed.get<realm::Decimal128>()];
        case realm::type_ObjectId:
            return [[RLMObjectId alloc] initWithValue:mixed.get<realm::ObjectId>()];
        case realm::type_TypedLink:
            return RLMObjectFromObjLink(realm, mixed.get<realm::ObjLink>(), classInfo->isSwiftClass());
        case realm::type_Link: {
            auto obj = classInfo->table()->get_object((mixed).get<realm::ObjKey>());
            return RLMCreateObjectAccessor(*classInfo, std::move(obj));
        }
        case realm::type_UUID:
            return [[NSUUID alloc] initWithRealmUUID:mixed.get<realm::UUID>()];
        case realm::type_LinkList:
            REALM_UNREACHABLE();
        default:
            @throw RLMException(@"Invalid data type for RLMPropertyTypeAny property.");
    }
}

realm::UUID RLMObjcToUUID(__unsafe_unretained id const value) {
    try {
        if (auto uuid = RLMDynamicCast<NSUUID>(value)) {
            return uuid.rlm_uuidValue;
        }
        if (auto string = RLMDynamicCast<NSString>(value)) {
            return realm::UUID(string.UTF8String);
        }
    }
    catch (std::exception const& e) {
        @throw RLMException(@"Cannot convert value '%@' of type '%@' to uuid: %s",
                            value, [value class], e.what());
    }
    @throw RLMException(@"Cannot convert value '%@' of type '%@' to uuid", value, [value class]);
}

realm::Decimal128 RLMObjcToDecimal128(__unsafe_unretained id const value) {
    try {
        if (!value || value == NSNull.null) {
            return realm::Decimal128(realm::null());
        }
        if (auto decimal = RLMDynamicCast<RLMDecimal128>(value)) {
            return decimal.decimal128Value;
        }
        if (auto string = RLMDynamicCast<NSString>(value)) {
            return realm::Decimal128(string.UTF8String);
        }
        if (auto decimal = RLMDynamicCast<NSDecimalNumber>(value)) {
            return realm::Decimal128(decimal.stringValue.UTF8String);
        }
        if (auto number = RLMDynamicCast<NSNumber>(value)) {
            auto type = number.objCType[0];
            if (type == *@encode(double) || type == *@encode(float)) {
                return realm::Decimal128(number.doubleValue);
            }
            else if (std::isupper(type)) {
                return realm::Decimal128(number.unsignedLongLongValue);
            }
            else {
                return realm::Decimal128(number.longLongValue);
            }
        }
    }
    catch (std::exception const& e) {
        @throw RLMException(@"Cannot convert value '%@' of type '%@' to decimal128: %s",
                            value, [value class], e.what());
    }
    @throw RLMException(@"Cannot convert value '%@' of type '%@' to decimal128", value, [value class]);
}

NSString *RLMDefaultDirectoryForBundleIdentifier(NSString *bundleIdentifier) {
#if TARGET_OS_TV
    (void)bundleIdentifier;
    // tvOS prohibits writing to the Documents directory, so we use the Library/Caches directory instead.
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
#elif TARGET_OS_IPHONE && !TARGET_OS_MACCATALYST
    (void)bundleIdentifier;
    // On iOS the Documents directory isn't user-visible, so put files there
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#else
    // On OS X it is, so put files in Application Support. If we aren't running
    // in a sandbox, put it in a subdirectory based on the bundle identifier
    // to avoid accidentally sharing files between applications
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    if (![[NSProcessInfo processInfo] environment][@"APP_SANDBOX_CONTAINER_ID"]) {
        if (!bundleIdentifier) {
            bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
        }
        if (!bundleIdentifier) {
            bundleIdentifier = [NSBundle mainBundle].executablePath.lastPathComponent;
        }

        path = [path stringByAppendingPathComponent:bundleIdentifier];

        // create directory
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return path;
#endif
}

NSDateFormatter *RLMISO8601Formatter() {
    // note: NSISO8601DateFormatter can't be used as it doesn't support milliseconds
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    dateFormatter.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    return dateFormatter;
}
