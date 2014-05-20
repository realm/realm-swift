////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMProperty.h"
#import "RLMProperty_Private.h"
#import "RLMObject.h"

// private properties
@interface RLMProperty ()
@property (nonatomic, assign) BOOL dynamic;
@property (nonatomic, assign) BOOL nonatomic;

@end

@implementation RLMProperty

-(instancetype)initWithName:(NSString *)name type:(RLMPropertyType)type column:(NSUInteger)column {
    self = [super init];
    if (self) {
        _name = name;
        _type = type;
        _column = column;
        [self updateAccessorNames];
        [self setObjcCodeFromType];
    }
    
    return self;
}

-(void)updateAccessorNames {
    // populate getter/setter names if generic
    if (!_getterName) {
        _getterName = _name;
    }
    if (!_setterName) {
        _setterName = [NSString stringWithFormat:@"set%c%@:", toupper(_name.UTF8String[0]), [_name substringFromIndex:1]];
    }
}

-(void)setObjcCodeFromType {
    switch (_type) {
        case RLMPropertyTypeInt:
            _objcType = 'i';
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
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid property type"
                                         userInfo:nil];
            break;
    }
}

// determine RLMPropertyType from objc code
-(void)parsePropertyTypeString:(const char *)code {
    _objcType = *(code);    // first char of type attr
    if (self.objcType == 'q') {
        _objcType = 'l';    // collapse these as they are the same
    }
    
    // map to RLMPropertyType
    switch (self.objcType) {
        case 'i':   // int
        case 'l':   // long
            _type = RLMPropertyTypeInt;
            break;
        case 'f':
            _type = RLMPropertyTypeFloat;
            break;
        case 'd':
            _type = RLMPropertyTypeDouble;
            break;
        case 'c':   // BOOL is stored as char - since rlm has no char type this is ok
        case 'B':
            _type = RLMPropertyTypeBool;
            break;
        case '@':
        {
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
            else if ([type hasPrefix:@"@\"RLMArray<"]) {
                // get object class and set type
                _objectClassName = [type substringWithRange:NSMakeRange(11, type.length-5)];
                _type = RLMPropertyTypeArray;
                
                // verify type
                Class cls = NSClassFromString(self.objectClassName);
                if (class_getSuperclass(cls) != RLMObject.class) {
                    @throw [NSException exceptionWithName:@"RLMException" reason:@"Encapsulated properties must descend from RLMObject" userInfo:nil];
                }
            }
            else {
                // get object class and set type
                _objectClassName = [type substringWithRange:NSMakeRange(2, type.length-3)];
                _type = RLMPropertyTypeObject;
                
                // verify type
                Class cls = NSClassFromString(self.objectClassName);
                if (class_getSuperclass(cls) != RLMObject.class) {
                    @throw [NSException exceptionWithName:@"RLMException" reason:@"Encapsulated properties must descend from RLMObject" userInfo:nil];
                }
            }
            break;
        }
        default:
            _type = RLMPropertyTypeNone;
            break;
    }
}

+(instancetype)propertyForObjectProperty:(objc_property_t)runtimeProp column:(NSUInteger)column
{
    // create new property
    NSString *name = [NSString stringWithUTF8String:property_getName(runtimeProp)];
    RLMProperty *prop = [RLMProperty new];
    prop->_name = name;
    prop->_column = column;
    
    // parse attributes
    unsigned int attCount;
    objc_property_attribute_t *atts = property_copyAttributeList(runtimeProp, &attCount);
    for (unsigned int a = 0; a < attCount; a++) {
        switch (*(atts[a].name)) {
            case 'T':
                [prop parsePropertyTypeString:atts[a].value];
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
    
    // make sure we have a valid type
    if (prop.type == RLMPropertyTypeNone) {
        NSString * reason = [NSString stringWithFormat:@"Can't persist property '%@' with incompatible type. "
                             "Add to ignoredPropertyNames: method to ignore.", prop.name];
        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
    }
    
    // update getter/setter names
    [prop updateAccessorNames];
    
    return prop;
}


@end



