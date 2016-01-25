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

#import "RLMProperty_Private.h"

#import "RLMArray.h"
#import "RLMListBase.h"
#import "RLMObject.h"
#import "RLMObject_Private.h"
#import "RLMOptionalBase.h"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

BOOL RLMPropertyTypeIsNullable(RLMPropertyType propertyType) {
    return propertyType != RLMPropertyTypeAny && propertyType != RLMPropertyTypeArray;
}

BOOL RLMPropertyTypeIsNumeric(RLMPropertyType propertyType) {
    switch (propertyType) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            return YES;
        default:
            return NO;
    }
}

@implementation RLMProperty
- (instancetype)initWithName:(NSString *)name
                        type:(RLMPropertyType)type
             objectClassName:(NSString *)objectClassName
                     indexed:(BOOL)indexed
                    optional:(BOOL)optional {
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _objectClassName = objectClassName;
        _indexed = indexed;
        _optional = optional;
        [self setObjcCodeFromType];
        [self updateAccessors];
    }

    return self;
}

-(void)updateAccessors {
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

-(void)setObjcCodeFromType {
    if (_optional) {
        _objcType = '@';
    }
    switch (_type) {
        case RLMPropertyTypeInt:
            _objcType = 'q';
            break;
        case RLMPropertyTypeBool:
            _objcType = 'c';
            break;
        case RLMPropertyTypeDouble:
            _objcType = 'd';
            break;
        case RLMPropertyTypeFloat:
            _objcType = 'f';
            break;
        case RLMPropertyTypeAny:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeData:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeObject:
        case RLMPropertyTypeString:
            _objcType = '@';
            break;
    }
}

// determine RLMPropertyType from objc code - returns true if valid type was found/set
-(BOOL)setTypeFromRawType {
    const char *code = _objcRawType.UTF8String;
    _objcType = *code;    // first char of type attr

    // map to RLMPropertyType
    switch (self.objcType) {
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
        case '@': {
            _optional = true;
            static const char arrayPrefix[] = "@\"RLMArray<";
            static const int arrayPrefixLen = sizeof(arrayPrefix) - 1;

            static const char numberPrefix[] = "@\"NSNumber<";
            static const int numberPrefixLen = sizeof(numberPrefix) - 1;

            if (code[1] == '\0') {
                // string is "@"
                _type = RLMPropertyTypeAny;
                _optional = false;
            }
            else if (strcmp(code, "@\"NSString\"") == 0) {
                _type = RLMPropertyTypeString;
            }
            else if (strcmp(code, "@\"NSDate\"") == 0) {
                _type = RLMPropertyTypeDate;
            }
            else if (strcmp(code, "@\"NSData\"") == 0) {
                _type = RLMPropertyTypeData;
            }
            else if (strncmp(code, arrayPrefix, arrayPrefixLen) == 0) {
                _optional = false;
                // get object class from type string - @"RLMArray<objectClassName>"
                _type = RLMPropertyTypeArray;
                _objectClassName = [[NSString alloc] initWithBytes:code + arrayPrefixLen
                                                            length:strlen(code + arrayPrefixLen) - 2 // drop trailing >"
                                                          encoding:NSUTF8StringEncoding];

                Class cls = [RLMSchema classForString:_objectClassName];
                if (!RLMIsObjectSubclass(cls)) {
                    @throw RLMException(@"'%@' is not supported as an RLMArray object type. RLMArrays can only contain instances of RLMObject subclasses. See https://realm.io/docs/objc/latest/#to-many for more information.", self.objectClassName);
                }
            }
            else if (strncmp(code, numberPrefix, numberPrefixLen) == 0) {
                // get number type from type string - @"NSNumber<objectClassName>"
                NSString *numberType = [[NSString alloc] initWithBytes:code + numberPrefixLen
                                                                length:strlen(code + numberPrefixLen) - 2 // drop trailing >"
                                                              encoding:NSUTF8StringEncoding];

                if ([numberType isEqualToString:@"RLMInt"]) {
                    _type = RLMPropertyTypeInt;
                }
                else if ([numberType isEqualToString:@"RLMFloat"]) {
                    _type = RLMPropertyTypeFloat;
                }
                else if ([numberType isEqualToString:@"RLMDouble"]) {
                    _type = RLMPropertyTypeDouble;
                }
                else if ([numberType isEqualToString:@"RLMBool"]) {
                    _type = RLMPropertyTypeBool;
                }
                else {
                    @throw RLMException(@"'%@' is not supported as an NSNumber object type. "
                                        @"NSNumbers can only be RLMInt, RLMFloat, RLMDouble, and RLMBool at the moment. "
                                        @"See https://realm.io/docs/objc/latest for more information.", numberType);
                }
            }
            else if (strcmp(code, "@\"NSNumber\"") == 0) {
                @throw RLMException(@"NSNumber properties require a protocol defining the contained type - example: NSNumber<RLMInt>.");
            }
            else if (strcmp(code, "@\"RLMArray\"") == 0) {
                @throw RLMException(@"RLMArray properties require a protocol defining the contained type - example: RLMArray<Person>.");
            }
            else {
                // for objects strip the quotes and @
                NSString *className = [_objcRawType substringWithRange:NSMakeRange(2, _objcRawType.length-3)];

                // verify type
                Class cls = [RLMSchema classForString:className];
                if (!RLMIsObjectSubclass(cls)) {
                    @throw RLMException(@"'%@' is not supported as an RLMObject property. All properties must be primitives, NSString, NSDate, NSData, RLMArray, or subclasses of RLMObject. See https://realm.io/docs/objc/latest/api/Classes/RLMObject.html for more information.", className);
                }

                _type = RLMPropertyTypeObject;
                _optional = true;
                _objectClassName = [cls className] ?: className;
            }
            return YES;
        }
        default:
            return NO;
    }
}

- (bool)parseObjcProperty:(objc_property_t)property {
    unsigned int count;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &count);

    bool ignore = false;
    for (size_t i = 0; i < count; ++i) {
        switch (*attrs[i].name) {
            case 'T':
                _objcRawType = @(attrs[i].value);
                break;
            case 'R':
                ignore = true;
                break;
            case 'N':
                // nonatomic
                break;
            case 'D':
                // dynamic
                break;
            case 'G':
                _getterName = @(attrs[i].value);
                break;
            case 'S':
                _setterName = @(attrs[i].value);
                break;
            default:
                break;
        }
    }
    free(attrs);

    return ignore;
}

- (instancetype)initSwiftPropertyWithName:(NSString *)name
                                  indexed:(BOOL)indexed
                                 property:(objc_property_t)property
                                 instance:(RLMObject *)obj {
    self = [super init];
    if (!self) {
        return nil;
    }

    _name = name;
    _indexed = indexed;

    if ([self parseObjcProperty:property]) {
        return nil;
    }

    id propertyValue = [obj valueForKey:_name];

    // convert array types to objc variant
    if ([_objcRawType isEqualToString:@"@\"RLMArray\""]) {
        _objcRawType = [NSString stringWithFormat:@"@\"RLMArray<%@>\"", [propertyValue objectClassName]];
    }
    else if ([_objcRawType isEqualToString:@"@\"NSNumber\""]) {
        const char *numberType = [propertyValue objCType];
        switch (*numberType) {
            case 'i':
            case 'l':
            case 'q':
                _objcRawType = @"@\"NSNumber<RLMInt>\"";
                break;
            case 'f':
                _objcRawType = @"@\"NSNumber<RLMFloat>\"";
                break;
            case 'd':
                _objcRawType = @"@\"NSNumber<RLMDouble>\"";
                break;
            case 'B':
            case 'c':
                _objcRawType = @"@\"NSNumber<RLMBool>\"";
                break;
            default:
                @throw RLMException(@"Can't persist NSNumber of type '%s': only integers, floats, doubles, and bools are currently supported.", numberType);
        }
    }

    void (^throwForPropertyName)(NSString *) = ^(NSString *propertyName){
        @throw RLMException(@"Can't persist property '%@' with incompatible type. "
                            "Add to Object.ignoredProperties() class method to ignore.", propertyName);
    };

    if (![self setTypeFromRawType]) {
        throwForPropertyName(self.name);
    }

    if (_type == RLMPropertyTypeAny && propertyValue != nil) {
        if ([propertyValue isKindOfClass:[NSString class]]) {
            // NSStrings are parsed as Any.
            _type = RLMPropertyTypeString;
        } else if (![propertyValue isKindOfClass:[RLMListBase class]] && ![propertyValue isKindOfClass:[RLMOptionalBase class]]) {
            // Don't throw if the property is a List/RealmOptional property because those types only
            // get reported to ObjC with Swift 1.2 and not 2+.
            throwForPropertyName(self.name);
        }
    } else if (_objcType == 'c') {
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
                    property:(objc_property_t)property
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _name = name;
    _indexed = indexed;

    if ([self parseObjcProperty:property]) {
        return nil;
    }

    if (![self setTypeFromRawType]) {
        @throw RLMException(@"Can't persist property '%@' with incompatible type. "
                             "Add to ignoredPropertyNames: method to ignore.", self.name);
    }

    // update getter/setter names
    [self updateAccessors];

    return self;
}

- (instancetype)initSwiftListPropertyWithName:(NSString *)name
                                         ivar:(Ivar)ivar
                              objectClassName:(NSString *)objectClassName {
    self = [super init];
    if (!self) {
        return nil;
    }

    _name = name;
    _type = RLMPropertyTypeArray;
    _objectClassName = objectClassName;
    _objcType = 't';
    _swiftIvar = ivar;

    // no obj-c property for generic lists, and thus no getter/setter names

    return self;
}

- (instancetype)initSwiftOptionalPropertyWithName:(NSString *)name
                                          indexed:(BOOL)indexed
                                             ivar:(Ivar)ivar
                                     propertyType:(RLMPropertyType)propertyType {
    self = [super init];
    if (!self) {
        return nil;
    }

    _name = name;
    _type = propertyType;
    _indexed = indexed;
    _objcType = '@';
    _swiftIvar = ivar;
    _optional = true;

    // no obj-c property for generic optionals, and thus no getter/setter names

    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    RLMProperty *prop = [[RLMProperty allocWithZone:zone] init];
    prop->_name = _name;
    prop->_type = _type;
    prop->_objcType = _objcType;
    prop->_objectClassName = _objectClassName;
    prop->_indexed = _indexed;
    prop->_getterName = _getterName;
    prop->_setterName = _setterName;
    prop->_getterSel = _getterSel;
    prop->_setterSel = _setterSel;
    prop->_isPrimary = _isPrimary;
    prop->_swiftIvar = _swiftIvar;
    prop->_optional = _optional;
    prop->_declarationIndex = _declarationIndex;

    return prop;
}

- (BOOL)isEqualToProperty:(RLMProperty *)property {
    return _type == property->_type
        && _indexed == property->_indexed
        && _isPrimary == property->_isPrimary
        && _optional == property->_optional
        && [_name isEqualToString:property->_name]
        && (_objectClassName == property->_objectClassName  || [_objectClassName isEqualToString:property->_objectClassName]);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ {\n\ttype = %@;\n\tobjectClassName = %@;\n\tindexed = %@;\n\tisPrimary = %@;\n\toptional = %@;\n}", self.name, RLMTypeToString(self.type), self.objectClassName, self.indexed ? @"YES" : @"NO", self.isPrimary ? @"YES" : @"NO", self.optional ? @"YES" : @"NO"];
}

@end
