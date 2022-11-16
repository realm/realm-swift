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

#import "RLMProperty_Private.hpp"

#import "RLMArray_Private.hpp"
#import "RLMDictionary_Private.hpp"
#import "RLMObject.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.h"
#import "RLMSchema_Private.h"
#import "RLMSet_Private.hpp"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

#import <realm/object-store/property.hpp>

static_assert((int)RLMPropertyTypeInt        == (int)realm::PropertyType::Int);
static_assert((int)RLMPropertyTypeBool       == (int)realm::PropertyType::Bool);
static_assert((int)RLMPropertyTypeFloat      == (int)realm::PropertyType::Float);
static_assert((int)RLMPropertyTypeDouble     == (int)realm::PropertyType::Double);
static_assert((int)RLMPropertyTypeString     == (int)realm::PropertyType::String);
static_assert((int)RLMPropertyTypeData       == (int)realm::PropertyType::Data);
static_assert((int)RLMPropertyTypeDate       == (int)realm::PropertyType::Date);
static_assert((int)RLMPropertyTypeObject     == (int)realm::PropertyType::Object);
static_assert((int)RLMPropertyTypeObjectId   == (int)realm::PropertyType::ObjectId);
static_assert((int)RLMPropertyTypeDecimal128 == (int)realm::PropertyType::Decimal);
static_assert((int)RLMPropertyTypeUUID       == (int)realm::PropertyType::UUID);
static_assert((int)RLMPropertyTypeAny        == (int)realm::PropertyType::Mixed);

BOOL RLMPropertyTypeIsComputed(RLMPropertyType propertyType) {
    return propertyType == RLMPropertyTypeLinkingObjects;
}

// Swift obeys the ARC naming conventions for method families (except for init)
// but the end result doesn't really work (using KVC on a method returning a
// retained value results in a leak, but not returning a retained value results
// in crashes). Objective-C makes properties with naming fitting the method
// families a compile error, so we just disallow them in Swift as well.
// http://clang.llvm.org/docs/AutomaticReferenceCounting.html#arc-method-families
void RLMValidateSwiftPropertyName(NSString *name) {
    // To belong to a method family, the property name must begin with the family
    // name followed by a non-lowercase letter (or nothing), with an optional
    // leading underscore
    const char *str = name.UTF8String;
    if (str[0] == '_')
        ++str;
    auto nameSize = strlen(str);

    // Note that "init" is deliberately not in this list because Swift does not
    // infer family membership for it.
    for (auto family : {"alloc", "new", "copy", "mutableCopy"}) {
        auto familySize = strlen(family);
        if (nameSize < familySize || !std::equal(str, str + familySize, family)) {
            continue;
        }
        if (familySize == nameSize || !islower(str[familySize])) {
            @throw RLMException(@"Property names beginning with '%s' are not "
                                 "supported. Swift follows ARC's ownership "
                                 "rules for methods based on their name, which "
                                 "results in memory leaks when accessing "
                                 "properties which return retained values via KVC.",
                                family);
        }
        return;
    }
}

static bool rawTypeShouldBeTreatedAsComputedProperty(NSString *rawType) {
    return [rawType isEqualToString:@"@\"RLMLinkingObjects\""] || [rawType hasPrefix:@"@\"RLMLinkingObjects<"];
}

@implementation RLMProperty

+ (instancetype)propertyForObjectStoreProperty:(const realm::Property &)prop {
    auto ret = [[RLMProperty alloc] initWithName:@(prop.name.c_str())
                                            type:static_cast<RLMPropertyType>(prop.type & ~realm::PropertyType::Flags)
                                 objectClassName:prop.object_type.length() ? @(prop.object_type.c_str()) : nil
                          linkOriginPropertyName:prop.link_origin_property_name.length() ? @(prop.link_origin_property_name.c_str()) : nil
                                         indexed:prop.is_indexed
                                        optional:isNullable(prop.type)];
    if (is_array(prop.type)) {
        ret->_array = true;
    }
    if (is_set(prop.type)) {
        ret->_set = true;
    }
    if (is_dictionary(prop.type)) {
        // TODO: We need a way to store the dictionary
        // key type in realm::Property once we support more
        // key types.
        ret->_dictionaryKeyType = RLMPropertyTypeString;
        ret->_dictionary = true;
    }
    if (!prop.public_name.empty()) {
        ret->_columnName = ret->_name;
        ret->_name = @(prop.public_name.c_str());
    }
    return ret;
}

- (instancetype)initWithName:(NSString *)name
                        type:(RLMPropertyType)type
             objectClassName:(NSString *)objectClassName
      linkOriginPropertyName:(NSString *)linkOriginPropertyName
                     indexed:(BOOL)indexed
                    optional:(BOOL)optional {
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _objectClassName = objectClassName;
        _linkOriginPropertyName = linkOriginPropertyName;
        _indexed = indexed;
        _optional = optional;
        [self updateAccessors];
    }

    return self;
}

- (void)updateAccessors {
    // populate getter/setter names if generic
    if (!_getterName) {
        _getterName = _name;
    }
    if (!_setterName) {
        // Objective-C setters only capitalize the first letter of the property name if it falls between 'a' and 'z'
        int asciiCode = [_name characterAtIndex:0];
        BOOL shouldUppercase = asciiCode >= 'a' && asciiCode <= 'z';
        NSString *firstChar = [_name substringToIndex:1];
        firstChar = shouldUppercase ? firstChar.uppercaseString : firstChar;
        _setterName = [NSString stringWithFormat:@"set%@%@:", firstChar, [_name substringFromIndex:1]];
    }

    _getterSel = NSSelectorFromString(_getterName);
    _setterSel = NSSelectorFromString(_setterName);
}

static std::optional<RLMPropertyType> typeFromProtocolString(const char *type) {
    if (strcmp(type, "RLMValue>\"") == 0) {
        return RLMPropertyTypeAny;
    }
    if (strncmp(type, "RLM", 3)) {
        return realm::none;
    }
    type += 3;
    if (strcmp(type, "Int>\"") == 0) {
        return RLMPropertyTypeInt;
    }
    if (strcmp(type, "Float>\"") == 0) {
        return RLMPropertyTypeFloat;
    }
    if (strcmp(type, "Double>\"") == 0) {
        return RLMPropertyTypeDouble;
    }
    if (strcmp(type, "Bool>\"") == 0) {
        return RLMPropertyTypeBool;
    }
    if (strcmp(type, "String>\"") == 0) {
        return RLMPropertyTypeString;
    }
    if (strcmp(type, "Data>\"") == 0) {
        return RLMPropertyTypeData;
    }
    if (strcmp(type, "Date>\"") == 0) {
        return RLMPropertyTypeDate;
    }
    if (strcmp(type, "Decimal128>\"") == 0) {
        return RLMPropertyTypeDecimal128;
    }
    if (strcmp(type, "ObjectId>\"") == 0) {
        return RLMPropertyTypeObjectId;
    }
    if (strcmp(type, "UUID>\"") == 0) {
        return RLMPropertyTypeUUID;
    }
    return realm::none;
}

// determine RLMPropertyType from objc code - returns true if valid type was found/set
- (BOOL)setTypeFromRawType:(NSString *)rawType {
    const char *code = rawType.UTF8String;
    switch (*code) {
        case 's':   // short
        case 'i':   // int
        case 'l':   // long
        case 'q':   // long long
            _type = RLMPropertyTypeInt;
            return YES;
        case 'f':
            _type = RLMPropertyTypeFloat;
            return YES;
        case 'd':
            _type = RLMPropertyTypeDouble;
            return YES;
        case 'c':   // BOOL is stored as char - since rlm has no char type this is ok
        case 'B':
            _type = RLMPropertyTypeBool;
            return YES;
        case '@':
            break;
        default:
            return NO;
    }

    _optional = true;
    static const char arrayPrefix[] = "@\"RLMArray<";
    static const int arrayPrefixLen = sizeof(arrayPrefix) - 1;

    static const char setPrefix[] = "@\"RLMSet<";
    static const int setPrefixLen = sizeof(setPrefix) - 1;

    static const char dictionaryPrefix[] = "@\"RLMDictionary<";
    static const int dictionaryPrefixLen = sizeof(dictionaryPrefix) - 1;

    static const char numberPrefix[] = "@\"NSNumber<";
    static const int numberPrefixLen = sizeof(numberPrefix) - 1;

    static const char linkingObjectsPrefix[] = "@\"RLMLinkingObjects";
    static const int linkingObjectsPrefixLen = sizeof(linkingObjectsPrefix) - 1;

    _array = strncmp(code, arrayPrefix, arrayPrefixLen) == 0;
    _set = strncmp(code, setPrefix, setPrefixLen) == 0;
    _dictionary = strncmp(code, dictionaryPrefix, dictionaryPrefixLen) == 0;

    if (strcmp(code, "@\"NSString\"") == 0) {
        _type = RLMPropertyTypeString;
    }
    else if (strcmp(code, "@\"NSDate\"") == 0) {
        _type = RLMPropertyTypeDate;
    }
    else if (strcmp(code, "@\"NSData\"") == 0) {
        _type = RLMPropertyTypeData;
    }
    else if (strcmp(code, "@\"RLMDecimal128\"") == 0) {
        _type = RLMPropertyTypeDecimal128;
    }
    else if (strcmp(code, "@\"RLMObjectId\"") == 0) {
        _type = RLMPropertyTypeObjectId;
    }
    else if (strcmp(code, "@\"NSUUID\"") == 0) {
        _type = RLMPropertyTypeUUID;
    }
    else if (strcmp(code, "@\"<RLMValue>\"") == 0) {
        _type = RLMPropertyTypeAny;
        // Mixed can represent a null type but can't explicitly be an optional type.
        _optional = false;
    }
    else if (_array || _set || _dictionary) {
        size_t prefixLen = 0;
        NSString *collectionName;
        if (_array) {
            prefixLen = arrayPrefixLen;
            collectionName = @"RLMArray";
        }
        else if (_set) {
            prefixLen = setPrefixLen;
            collectionName = @"RLMSet";
        }
        else if (_dictionary) {
            // get the type, by working backward from RLMDictionary<Key, Type>
            size_t typeLen = 0;
            size_t codeSize = strlen(code);
            for (size_t i = codeSize; i > 0; i--) {
                if (code[i] == '>' && i != (codeSize-2)) { // -2 means we skip the first time we see '>'
                    typeLen = i;
                    break;
                }
            }
            prefixLen = typeLen+size_t(2); // +2 start at the type name
            collectionName = @"RLMDictionary";

            // Get the key type
            if (strstr(code + dictionaryPrefixLen, "RLMString><") != NULL) {
                _dictionaryKeyType = RLMPropertyTypeString;
            }
        }

        if (auto type = typeFromProtocolString(code + prefixLen)) {
            _type = *type;
            return YES;
        }

        // get object class from type string - @"RLMSomeCollection<objectClassName>"
        _objectClassName = [[NSString alloc] initWithBytes:code + prefixLen
                                                    length:strlen(code + prefixLen) - 2 // drop trailing >"
                                                  encoding:NSUTF8StringEncoding];

        if ([RLMSchema classForString:_objectClassName]) {
            // Dictionaries require object types to be nullable. This is due to
            // the fact that if you delete a realm object that exists in a dictionary
            // the key should stay present but the value should be null.
            _optional = _dictionary;
            _type = RLMPropertyTypeObject;
            return YES;
        }
        @throw RLMException(@"Property '%@' is of type '%@<%@>' which is not a supported %@ object type. "
                            @"%@ can only contain instances of RLMObject subclasses. "
                            @"See https://www.mongodb.com/docs/realm/sdk/swift/fundamentals/relationships/#to-many-relationship "
                            @"for more information.", _name, collectionName, _objectClassName, collectionName, collectionName);
    }
    else if (strncmp(code, numberPrefix, numberPrefixLen) == 0) {
        auto type = typeFromProtocolString(code + numberPrefixLen);
        if (type && (*type == RLMPropertyTypeInt || *type == RLMPropertyTypeFloat || *type == RLMPropertyTypeDouble || *type == RLMPropertyTypeBool)) {
            _type = *type;
            return YES;
        }
        @throw RLMException(@"Property '%@' is of type %s which is not a supported NSNumber object type. "
                            @"NSNumbers can only be RLMInt, RLMFloat, RLMDouble, and RLMBool at the moment. "
                            @"See https://www.mongodb.com/docs/realm/sdk/swift/data-types/supported-property-types/ "
                            @"for more information.", _name, code + 1);
    }
    else if (strncmp(code, linkingObjectsPrefix, linkingObjectsPrefixLen) == 0 &&
             (code[linkingObjectsPrefixLen] == '"' || code[linkingObjectsPrefixLen] == '<')) {
        _type = RLMPropertyTypeLinkingObjects;
        _optional = false;
        _array = true;

        if (!_objectClassName || !_linkOriginPropertyName) {
            @throw RLMException(@"Property '%@' is of type RLMLinkingObjects but +linkingObjectsProperties did not specify the class "
                                "or property that is the origin of the link.", _name);
        }

        // If the property was declared with a protocol indicating the contained type, validate that it matches
        // the class from the dictionary returned by +linkingObjectsProperties.
        if (code[linkingObjectsPrefixLen] == '<') {
            NSString *classNameFromProtocol = [[NSString alloc] initWithBytes:code + linkingObjectsPrefixLen + 1
                                                                       length:strlen(code + linkingObjectsPrefixLen) - 3 // drop trailing >"
                                                                     encoding:NSUTF8StringEncoding];
            if (![_objectClassName isEqualToString:classNameFromProtocol]) {
                @throw RLMException(@"Property '%@' was declared with type RLMLinkingObjects<%@>, but a conflicting "
                                    "class name of '%@' was returned by +linkingObjectsProperties.", _name,
                                    classNameFromProtocol, _objectClassName);
            }
        }
    }
    else if (strcmp(code, "@\"NSNumber\"") == 0) {
        @throw RLMException(@"Property '%@' requires a protocol defining the contained type - example: NSNumber<RLMInt>.", _name);
    }
    else if (strcmp(code, "@\"RLMArray\"") == 0) {
        @throw RLMException(@"Property '%@' requires a protocol defining the contained type - example: RLMArray<Person>.", _name);
    }
    else if (strcmp(code, "@\"RLMSet\"") == 0) {
        @throw RLMException(@"Property '%@' requires a protocol defining the contained type - example: RLMSet<Person>.", _name);
    }
    else if (strcmp(code, "@\"RLMDictionary\"") == 0) {
        @throw RLMException(@"Property '%@' requires a protocol defining the contained type - example: RLMDictionary<NSString *, Person *><RLMString, Person>.", _name);
    }
    else {
        NSString *className;
        Class cls = nil;
        if (code[1] == '\0') {
            className = @"id";
        }
        else {
            // for objects strip the quotes and @
            className = [rawType substringWithRange:NSMakeRange(2, rawType.length-3)];
            cls = [RLMSchema classForString:className];
        }

        if (!cls) {
            @throw RLMException(@"Property '%@' is declared as '%@', which is not a supported RLMObject property type. "
                                @"All properties must be primitives, NSString, NSDate, NSData, NSNumber, RLMArray, RLMSet, "
                                @"RLMDictionary, RLMLinkingObjects, RLMDecimal128, RLMObjectId, or subclasses of RLMObject. "
                                @"See https://www.mongodb.com/docs/realm-legacy/docs/objc/latest/api/Classes/RLMObject.html "
                                @"for more information.", _name, className);
        }

        _type = RLMPropertyTypeObject;
        _optional = true;
        _objectClassName = [cls className] ?: className;
    }
    return YES;
}

- (void)parseObjcProperty:(objc_property_t)property
                 readOnly:(bool *)readOnly
                 computed:(bool *)computed
                  rawType:(NSString **)rawType {
    unsigned int count;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &count);

    *computed = true;
    for (size_t i = 0; i < count; ++i) {
        switch (*attrs[i].name) {
            case 'T':
                *rawType = @(attrs[i].value);
                break;
            case 'R':
                *readOnly = true;
                break;
            case 'G':
                _getterName = @(attrs[i].value);
                break;
            case 'S':
                _setterName = @(attrs[i].value);
                break;
            case 'V': // backing ivar name
                *computed = false;
                break;

            case '&':
                // retain/assign
                break;
            case 'C':
                // copy
                break;
            case 'D':
                // dynamic
                break;
            case 'N':
                // nonatomic
                break;
            case 'P':
                // GC'able
                break;
            case 'W':
                // weak
                break;
            default:
                break;
        }
    }
    free(attrs);
}

- (instancetype)initSwiftPropertyWithName:(NSString *)name
                                  indexed:(BOOL)indexed
                   linkPropertyDescriptor:(RLMPropertyDescriptor *)linkPropertyDescriptor
                                 property:(objc_property_t)property
                                 instance:(RLMObject *)obj {
    self = [super init];
    if (!self) {
        return nil;
    }

    RLMValidateSwiftPropertyName(name);

    _name = name;
    _indexed = indexed;

    if (linkPropertyDescriptor) {
        _objectClassName = [linkPropertyDescriptor.objectClass className];
        _linkOriginPropertyName = linkPropertyDescriptor.propertyName;
    }

    NSString *rawType;
    bool readOnly = false;
    bool isComputed = false;
    [self parseObjcProperty:property readOnly:&readOnly computed:&isComputed rawType:&rawType];

    // Swift sometimes doesn't explicitly set the ivar name in the metadata, so check if
    // there's an ivar with the same name as the property.
    if (!readOnly && isComputed && class_getInstanceVariable([obj class], name.UTF8String)) {
        isComputed = false;
    }

    // Check if there's a storage ivar for a lazy property in this name. We don't honor
    // @lazy in managed objects, but allow it for unmanaged objects which are
    // subclasses of RLMObject (but not RealmSwift.Object). It's unclear if there's a
    // good reason for this difference.
    if (!readOnly && isComputed) {
        // Xcode 10 and earlier
        NSString *backingPropertyName = [NSString stringWithFormat:@"%@.storage", name];
        isComputed = !class_getInstanceVariable([obj class], backingPropertyName.UTF8String);
    }
    if (!readOnly && isComputed) {
        // Xcode 11
        NSString *backingPropertyName = [NSString stringWithFormat:@"$__lazy_storage_$_%@", name];
        isComputed = !class_getInstanceVariable([obj class], backingPropertyName.UTF8String);
    }

    if (readOnly || isComputed) {
        return nil;
    }

    id propertyValue = [obj valueForKey:_name];

    // FIXME: temporarily workaround added since Objective-C generics used in Swift show up as `@`
    //        * broken starting in Swift 3.0 Xcode 8 b1
    //        * tested to still be broken in Swift 3.0 Xcode 8 b6
    //        * if the Realm Objective-C Swift tests pass with this removed, it's been fixed
    //        * once it has been fixed, remove this entire conditional block (contents included) entirely
    //        * Bug Report: SR-2031 https://bugs.swift.org/browse/SR-2031
    if ([rawType isEqualToString:@"@"]) {
        if (propertyValue) {
            rawType = [NSString stringWithFormat:@"@\"%@\"", [propertyValue class]];
        } else if (linkPropertyDescriptor) {
            // we're going to naively assume that the user used the correct type since we can't check it
            rawType = @"@\"RLMLinkingObjects\"";
        }
    }

    // convert array / set / dictionary types to objc variant
    if ([rawType isEqualToString:@"@\"RLMArray\""]) {
        RLMArray *value = propertyValue;
        _type = value.type;
        _optional = value.optional;
        _array = true;
        _objectClassName = value.objectClassName;
        if (_type == RLMPropertyTypeObject && ![RLMSchema classForString:_objectClassName]) {
            @throw RLMException(@"Property '%@' is of type 'RLMArray<%@>' which is not a supported RLMArray object type. "
                                @"RLMArrays can only contain instances of RLMObject subclasses. "
                                @"See https://www.mongodb.com/docs/realm/sdk/swift/fundamentals/relationships/#to-many-relationship "
                                @"for more information.", _name, _objectClassName);
        }
    }
    else if ([rawType isEqualToString:@"@\"RLMSet\""]) {
        RLMSet *value = propertyValue;
        _type = value.type;
        _optional = value.optional;
        _set = true;
        _objectClassName = value.objectClassName;
        if (_type == RLMPropertyTypeObject && ![RLMSchema classForString:_objectClassName]) {
            @throw RLMException(@"Property '%@' is of type 'RLMSet<%@>' which is not a supported RLMSet object type. "
                                @"RLMSets can only contain instances of RLMObject subclasses. "
                                @"See https://www.mongodb.com/docs/realm/sdk/swift/fundamentals/relationships/#to-many-relationship "
                                @"for more information.", _name, _objectClassName);
        }
    }
    else if ([rawType isEqualToString:@"@\"RLMDictionary\""]) {
        RLMDictionary *value = propertyValue;
        _type = value.type;
        _dictionaryKeyType = value.keyType;
        _optional = value.optional;
        _dictionary = true;
        _objectClassName = value.objectClassName;
        if (_type == RLMPropertyTypeObject && ![RLMSchema classForString:_objectClassName]) {
            @throw RLMException(@"Property '%@' is of type 'RLMDictionary<KeyType, %@>' which is not a supported RLMDictionary object type. "
                                @"RLMDictionarys can only contain instances of RLMObject subclasses. "
                                @"See https://www.mongodb.com/docs/realm/sdk/swift/fundamentals/relationships/#to-many-relationship "
                                @"for more information.", _name, _objectClassName);
        }
    }
    else if ([rawType isEqualToString:@"@\"NSNumber\""]) {
        const char *numberType = [propertyValue objCType];
        if (!numberType) {
            @throw RLMException(@"Can't persist NSNumber without default value: use a Swift-native number type or provide a default value.");
        }
        _optional = true;
        switch (*numberType) {
            case 'i': case 'l': case 'q':
                _type = RLMPropertyTypeInt;
                break;
            case 'f':
                _type = RLMPropertyTypeFloat;
                break;
            case 'd':
                _type = RLMPropertyTypeDouble;
                break;
            case 'B': case 'c':
                _type = RLMPropertyTypeBool;
                break;
            default:
                @throw RLMException(@"Can't persist NSNumber of type '%s': only integers, floats, doubles, and bools are currently supported.", numberType);
        }
    }
    else if (![self setTypeFromRawType:rawType]) {
        @throw RLMException(@"Can't persist property '%@' with incompatible type. "
                            "Add to Object.ignoredProperties() class method to ignore.",
                            self.name);
    }

    if ([rawType isEqualToString:@"c"]) {
        // Check if it's a BOOL or Int8 by trying to set it to 2 and seeing if
        // it actually sets it to 1.
        [obj setValue:@2 forKey:name];
        NSNumber *value = [obj valueForKey:name];
        _type = value.intValue == 2 ? RLMPropertyTypeInt : RLMPropertyTypeBool;
    }

    // update getter/setter names
    [self updateAccessors];

    return self;
}

- (instancetype)initWithName:(NSString *)name
                     indexed:(BOOL)indexed
      linkPropertyDescriptor:(RLMPropertyDescriptor *)linkPropertyDescriptor
                    property:(objc_property_t)property
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _name = name;
    _indexed = indexed;

    if (linkPropertyDescriptor) {
        _objectClassName = [linkPropertyDescriptor.objectClass className];
        _linkOriginPropertyName = linkPropertyDescriptor.propertyName;
    }

    NSString *rawType;
    bool isReadOnly = false;
    bool isComputed = false;
    [self parseObjcProperty:property readOnly:&isReadOnly computed:&isComputed rawType:&rawType];
    bool shouldBeTreatedAsComputedProperty = rawTypeShouldBeTreatedAsComputedProperty(rawType);
    if ((isReadOnly || isComputed) && !shouldBeTreatedAsComputedProperty) {
        return nil;
    }

    if (![self setTypeFromRawType:rawType]) {
        @throw RLMException(@"Can't persist property '%@' with incompatible type. "
                             "Add to ignoredPropertyNames: method to ignore.", self.name);
    }

    if (!isReadOnly && shouldBeTreatedAsComputedProperty) {
        @throw RLMException(@"Property '%@' must be declared as readonly as %@ properties cannot be written to.",
                            self.name, RLMTypeToString(_type));
    }

    // update getter/setter names
    [self updateAccessors];

    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    RLMProperty *prop = [[RLMProperty allocWithZone:zone] init];
    prop->_name = _name;
    prop->_columnName = _columnName;
    prop->_type = _type;
    prop->_objectClassName = _objectClassName;
    prop->_array = _array;
    prop->_set = _set;
    prop->_dictionary = _dictionary;
    prop->_dictionaryKeyType = _dictionaryKeyType;
    prop->_indexed = _indexed;
    prop->_getterName = _getterName;
    prop->_setterName = _setterName;
    prop->_getterSel = _getterSel;
    prop->_setterSel = _setterSel;
    prop->_isPrimary = _isPrimary;
    prop->_swiftAccessor = _swiftAccessor;
    prop->_swiftIvar = _swiftIvar;
    prop->_optional = _optional;
    prop->_linkOriginPropertyName = _linkOriginPropertyName;
    return prop;
}

- (RLMProperty *)copyWithNewName:(NSString *)name {
    RLMProperty *prop = [self copy];
    prop.name = name;
    return prop;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMProperty class]]) {
        return NO;
    }

    return [self isEqualToProperty:object];
}

- (BOOL)isEqualToProperty:(RLMProperty *)property {
    return _type == property->_type
        && _indexed == property->_indexed
        && _isPrimary == property->_isPrimary
        && _optional == property->_optional
        && [_name isEqualToString:property->_name]
        && (_objectClassName == property->_objectClassName  || [_objectClassName isEqualToString:property->_objectClassName])
        && (_linkOriginPropertyName == property->_linkOriginPropertyName ||
            [_linkOriginPropertyName isEqualToString:property->_linkOriginPropertyName]);
}

- (BOOL)collection {
    return self.set || self.array || self.dictionary;
}

- (NSString *)description {
    NSString *objectClassName = @"";
    if (self.type == RLMPropertyTypeObject || self.type == RLMPropertyTypeLinkingObjects) {
        objectClassName = [NSString stringWithFormat:
                           @"\tobjectClassName = %@;\n"
                           @"\tlinkOriginPropertyName = %@;\n",
                           self.objectClassName, self.linkOriginPropertyName];
    }
    return [NSString stringWithFormat:
            @"%@ {\n"
             "\ttype = %@;\n"
             "%@"
             "\tcolumnName = %@;\n"
             "\tindexed = %@;\n"
             "\tisPrimary = %@;\n"
             "\tarray = %@;\n"
             "\tset = %@;\n"
             "\tdictionary = %@;\n"
             "\toptional = %@;\n"
             "}",
            self.name, RLMTypeToString(self.type),
            objectClassName,
            self.columnName,
            self.indexed ? @"YES" : @"NO",
            self.isPrimary ? @"YES" : @"NO",
            self.array ? @"YES" : @"NO",
            self.set ? @"YES" : @"NO",
            self.dictionary ? @"YES" : @"NO",
            self.optional ? @"YES" : @"NO"];
}

- (NSString *)columnName {
    return _columnName ?: _name;
}

- (realm::Property)objectStoreCopy:(RLMSchema *)schema {
    realm::Property p;
    p.name = self.columnName.UTF8String;
    if (_columnName) {
        p.public_name = _name.UTF8String;
    }
    if (_objectClassName) {
        RLMObjectSchema *targetSchema = schema[_objectClassName];
        p.object_type = (targetSchema.objectName ?: _objectClassName).UTF8String;
        if (_linkOriginPropertyName) {
            p.link_origin_property_name = (targetSchema[_linkOriginPropertyName].columnName ?: _linkOriginPropertyName).UTF8String;
        }
    }
    p.is_indexed = static_cast<bool>(_indexed);
    p.type = static_cast<realm::PropertyType>(_type);
    if (_array) {
        p.type |= realm::PropertyType::Array;
    }
    if (_set) {
        p.type |= realm::PropertyType::Set;
    }
    if (_dictionary) {
        p.type |= realm::PropertyType::Dictionary;
    }
    if (_optional || p.type == realm::PropertyType::Mixed) {
        p.type |= realm::PropertyType::Nullable;
    }
    return p;
}

- (NSString *)typeName {
    if (!self.collection) {
        return RLMTypeToString(_type);
    }
    NSString *collectionName;
    if (_swiftAccessor) {
        collectionName = _array ? @"List" :
                         _set   ? @"MutableSet" :
                                  @"Map";
    }
    else {
        collectionName = _array ? @"RLMArray" :
                         _set   ? @"RLMSet" :
                                  @"RLMDictionary";
    }
    return [NSString stringWithFormat:@"%@<%@>", collectionName, RLMTypeToString(_type)];
}

@end

@implementation RLMPropertyDescriptor

+ (instancetype)descriptorWithClass:(Class)objectClass propertyName:(NSString *)propertyName
{
    RLMPropertyDescriptor *descriptor = [[RLMPropertyDescriptor alloc] init];
    descriptor->_objectClass = objectClass;
    descriptor->_propertyName = propertyName;
    return descriptor;
}

@end
