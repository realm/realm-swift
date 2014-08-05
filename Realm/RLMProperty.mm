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

#import "RLMObject.h"
#import "RLMProperty.h"
#import "RLMProperty_Private.h"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

// private properties
@interface RLMProperty ()

@property (nonatomic, assign) BOOL dynamic;
@property (nonatomic, assign) BOOL nonatomic;

@end

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
        [self updateAccessorNames];
        [self setObjcCodeFromType];
    }

    return self;
}

+ (instancetype)propertyWithName:(NSString *)name type:(RLMPropertyType)type objectClassName:(NSString *)objectClassName {
    RLMProperty *prop = [[RLMProperty alloc] init];
    prop->_name = name;
    prop->_type = type;
    prop->_objectClassName = objectClassName;
    [prop updateAccessorNames];
    [prop setObjcCodeFromType];
    return prop;
}

-(void)updateAccessorNames {
    // populate getter/setter names if generic
    if (!_getterName) {
        _getterName = _name;
    }
    if (!_setterName) {
        // Objective-C setters only capitalize the first letter of the property name if it falls between 'A' and 'z'
        int asciiCode = [_name characterAtIndex:0];
        BOOL shouldUppercase = asciiCode > 'A' && asciiCode < 'z';
        NSString *firstChar = [_name substringToIndex:1];
        firstChar = shouldUppercase ? firstChar.uppercaseString : firstChar;
        _setterName = [NSString stringWithFormat:@"set%@%@:", firstChar, [_name substringFromIndex:1]];
    }
}

-(void)setObjcCodeFromType {
    switch (_type) {
        case RLMPropertyTypeInt:
#if defined(__LP64__) && __LP64__
            _objcType = 'l';
#else
            _objcType = 'i';
#endif
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
-(BOOL)parsePropertyTypeString:(const char *)code {
    _objcType = *(code);    // first char of type attr
    if (self.objcType == 'q') {
        _objcType = 'l';    // collapse these as they are the same
    }

    // map to RLMPropertyType
    switch (self.objcType) {
        case 'i':   // int
        case 'l':   // long
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
        {
            NSString *const arrayPrefix = @"@\"RLMArray<";
            NSString *type = [NSString stringWithUTF8String:code];
            // if one charachter, this is an untyped id, ie [type isEqualToString:@"@"]
            if (type.length == 1) {
                _type = RLMPropertyTypeAny;
            }
            else if ([type isEqualToString:@"@\"NSString\""]) {
                _type = RLMPropertyTypeString;
            }
            else if ([type isEqualToString:@"@\"NSDate\""]) {
                _type = RLMPropertyTypeDate;
            }
            else if ([type isEqualToString:@"@\"NSData\""]) {
                _type = RLMPropertyTypeData;
            }
            else if ([type hasPrefix:arrayPrefix]) {
                // get object class from type string - @"RLMArray<objectClassName>"
                _objectClassName = [type substringWithRange:NSMakeRange(arrayPrefix.length, type.length-arrayPrefix.length-2)];
                _type = RLMPropertyTypeArray;

                // verify type
                Class cls = [RLMSchema classForString:self.objectClassName];
                if (!RLMIsObjectSubclass(cls)) {
                    @throw [NSException exceptionWithName:@"RLMException"
                                                   reason:[NSString stringWithFormat:@"RLMArray sub-type '%@' must descend from RLMObject", self.objectClassName]
                                                 userInfo:nil];
                }
            }
            else if ([type isEqualToString:@"@\"NSNumber\""]) {
                @throw [NSException exceptionWithName:@"RLMException"
                                               reason:[NSString stringWithFormat:@"'NSNumber' is not supported as an RLMObject property. Supported number types include int, long, float, double, and other primitive number types. See http://realm.io/docs/cocoa/latest/api/Constants/RLMPropertyType.html for all supported types."]
                                             userInfo:nil];
            }
            else {
                // get object class and set type
                _objectClassName = [type substringWithRange:NSMakeRange(2, type.length-3)];
                _type = RLMPropertyTypeObject;

                // verify type
                Class cls = [RLMSchema classForString:self.objectClassName];
                if (!RLMIsObjectSubclass(cls)) {
                    if ([_objectClassName isEqualToString:@"RLMArray"]) {
                        @throw [NSException exceptionWithName:@"RLMException"
                                                       reason:@"RLMArray properties require a protocol defining the contained type - example: RLMArray<Person>"
                                                     userInfo:nil];
                    }
                    @throw [NSException exceptionWithName:@"RLMException"
                                                   reason:[NSString stringWithFormat:@"'%@' is not supported as an RLMObject property. All properties must be primitives, NSString, NSDate, NSData, RLMArray, or subclasses of RLMObject. See http://realm.io/docs/cocoa/latest/api/Classes/RLMObject.html for more information.", self.objectClassName]
                                                 userInfo:nil];
                }
            }
            return YES;
        }
        default:
            return NO;
    }
}

+(instancetype)propertyForObjectProperty:(objc_property_t)runtimeProp
                              attributes:(RLMPropertyAttributes)attributes
{
    // create new property
    NSString *name = [NSString stringWithUTF8String:property_getName(runtimeProp)];
    RLMProperty *prop = [RLMProperty new];
    prop->_name = name;
    prop->_attributes = attributes;

    // parse attributes
    unsigned int attCount;
    objc_property_attribute_t *atts = property_copyAttributeList(runtimeProp, &attCount);
    BOOL validType = NO;
    for (unsigned int a = 0; a < attCount; a++) {
        switch (*(atts[a].name)) {
            case 'T':
                validType = [prop parsePropertyTypeString:atts[a].value];
                break;
            case 'N':
                prop.nonatomic = YES;
                break;
            case 'D':
                prop.dynamic = YES;
                break;
            case 'G':
                prop.getterName = [NSString stringWithUTF8String:atts[a].value];
                break;
            case 'S':
                prop.setterName = [NSString stringWithUTF8String:atts[a].value];
                break;
            default:
                break;
        }
    }
    free(atts);

    // throw if there was no type
    if (!validType) {
        NSString * reason = [NSString stringWithFormat:@"Can't persist property '%@' with incompatible type. "
                             "Add to ignoredPropertyNames: method to ignore.", prop.name];
        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
    }

    // update getter/setter names
    [prop updateAccessorNames];

    return prop;
}


-(BOOL)isEqualToProperty:(RLMProperty *)prop {
    return [_name isEqualToString:prop.name] && _type == prop.type &&
           (_objectClassName == nil || [_objectClassName isEqualToString:prop.objectClassName]);
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:RLMProperty.class]) {
        return NO;
    }
    return [self isEqualToProperty:object];
}

@end
