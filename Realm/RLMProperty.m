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
#import "RLMObject.h"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"

@implementation RLMProperty

- (instancetype)initWithName:(NSString *)name
                        type:(RLMPropertyType)type
             objectClassName:(NSString *)objectClassName
                  attributes:(RLMPropertyAttributes)attributes {
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _objectClassName = objectClassName;
        _attributes = attributes;
        [self setObjcCodeFromType];
        [self updateAccessorNames];
    }

    return self;
}

-(void)updateAccessorNames {
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
}

-(void)setObjcCodeFromType {
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
-(BOOL)parsePropertyTypeString:(const char *)code instance:(RLMObject *)obj {
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
            if (code[1] == '\0') {
                // type is just "@", which means it's either `id` or a Swift
                // `String`, so check the type of the value from the instance
                if ([[obj valueForKey:_name] isKindOfClass:[NSString class]]) {
                    _type = RLMPropertyTypeString;
                }
                else {
                    _type = RLMPropertyTypeAny;
                }
                return YES;
            }

            static const char arrayPrefix[] = "@\"RLMArray<";
            static const int arrayPrefixLen = sizeof(arrayPrefix) - 1;

            NSString *type = @(code);
            if (strcmp(code, "@\"NSString\"") == 0) {
                _type = RLMPropertyTypeString;
            }
            else if (strcmp(code, "@\"NSDate\"") == 0) {
                _type = RLMPropertyTypeDate;
            }
            else if (strcmp(code, "@\"NSData\"") == 0) {
                _type = RLMPropertyTypeData;
            }
            else if (strncmp(code, arrayPrefix, arrayPrefixLen) == 0) {
                // get object class from type string - @"RLMArray<objectClassName>"
                [self setArrayObjectClassName:[[NSString alloc] initWithBytes:code + arrayPrefixLen
                                                                       length:strlen(code + arrayPrefixLen) - 2 // drop trailing >"
                                                                     encoding:NSUTF8StringEncoding]];
            }
            else if ([type isEqualToString:@"@\"NSNumber\""]) {
                @throw [NSException exceptionWithName:@"RLMException"
                                               reason:[NSString stringWithFormat:@"'NSNumber' is not supported as an RLMObject property. Supported number types include int, long, float, double, and other primitive number types. See http://realm.io/docs/cocoa/latest/api/Constants/RLMPropertyType.html for all supported types."]
                                             userInfo:nil];
            }
            else if ([type isEqualToString:@"@\"RLMArray\""]) {
                if (!obj) { // obj-c case
                    @throw [NSException exceptionWithName:@"RLMException"
                                                   reason:@"RLMArray properties require a protocol defining the contained type - example: RLMArray<Person>"
                                                 userInfo:nil];
                }

                // swift case
                [self setArrayObjectClassName:[[obj valueForKey:_name] objectClassName]];
            }
            else {
                NSString *className = [type substringWithRange:NSMakeRange(2, type.length-3)];

                // verify type
                Class cls = [RLMSchema classForString:className];
                if (class_getSuperclass(cls) != RLMObject.class) {
                    @throw [NSException exceptionWithName:@"RLMException"
                                                   reason:[NSString stringWithFormat:@"'%@' is not supported as an RLMObject property. All properties must be primitives, NSString, NSDate, NSData, RLMArray, or subclasses of RLMObject. See http://realm.io/docs/cocoa/latest/api/Classes/RLMObject.html for more information.", self.objectClassName]
                                                 userInfo:nil];
                }

                _type = RLMPropertyTypeObject;
                _objectClassName = [cls className];
            }
            return YES;
        }
        default:
            return NO;
    }
}

- (void)setArrayObjectClassName:(NSString *)objectClassName {
    Class cls = [RLMSchema classForString:objectClassName];
    if (class_getSuperclass(cls) != RLMObject.class) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:[NSString stringWithFormat:@"RLMArray sub-type '%@' must descend from RLMObject", self.objectClassName]
                                     userInfo:nil];
    }

    _type = RLMPropertyTypeArray;
    _objectClassName = [cls className];
}

- (instancetype)initWithName:(NSString *)name
                  attributes:(RLMPropertyAttributes)attributes
                    property:(objc_property_t)property
                    instance:(RLMObject *)objectInstance
{
    self = [super init];
    if (!self) {
        return self;
    }

    _name = name;
    _attributes = attributes;

    unsigned int count;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &count);

    // parse attributes
    BOOL validType = NO;
    for (size_t i = 0; i < count; ++i) {
        switch (*attrs[i].name) {
            case 'T':
                validType = [self parsePropertyTypeString:attrs[i].value instance:objectInstance];
                break;
            case 'N':
                // nonatomic
                break;
            case 'D':
                // dynamic
                break;
            case 'G':
                self.getterName = @(attrs[i].value);
                break;
            case 'S':
                self.setterName = @(attrs[i].value);
                break;
            default:
                break;
        }
    }
    free(attrs);

    // throw if there was no type
    if (!validType) {
        NSString *reason = [NSString stringWithFormat:@"Can't persist property '%@' with incompatible type. "
                             "Add to ignoredPropertyNames: method to ignore.", self.name];
        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
    }

    // update getter/setter names
    [self updateAccessorNames];

    return self;
}


-(BOOL)isEqualToProperty:(RLMProperty *)prop {
    return [_name isEqualToString:prop.name] && _type == prop.type && prop.isPrimary == _isPrimary &&
           (_objectClassName == nil || [_objectClassName isEqualToString:prop.objectClassName]);
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:RLMProperty.class]) {
        return NO;
    }
    return [self isEqualToProperty:object];
}

@end
