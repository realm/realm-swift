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
#import "RLMObjectSchema.h"
#import "RLMPrivate.hpp"
#import "RLMUtil.h"
#import "RLMObjectStore.h"

// private properties
@interface RLMProperty ()
@property (nonatomic, assign) BOOL dynamic;
@property (nonatomic, assign) BOOL nonatomic;
@end

@implementation RLMProperty

@synthesize getterName = _getterName;
@synthesize setterName = _setterName;


// determine RLMPropertyType from objc code
-(void)parsePropertyTypeString:(const char *)code {
    self.objcType = *(code);    // first char of type attr
    if (self.objcType == 'q') {
        self.objcType = 'l';    // collapse these as they are the same
    }
    
    // map to RLMPropertyType
    switch (self.objcType) {
        case 'i':   // int
        case 'l':   // long
            self.type = RLMPropertyTypeInt;
            break;
        case 'f':
            self.type = RLMPropertyTypeFloat;
            break;
        case 'd':
            self.type = RLMPropertyTypeDouble;
            break;
        case 'c':   // BOOL is stored as char - since rlm has no char type this is ok
        case 'B':
            self.type = RLMPropertyTypeBool;
            break;
        case '@':
        {
            NSString *type = [NSString stringWithUTF8String:code];
            // if one charachter, this is an untyped id, ie [type isEqualToString:@"@"]
            if (type.length == 1) {
                self.type = RLMPropertyTypeAny;
            }
            else if ([type isEqualToString:@"@\"NSString\""]) {
                self.type = RLMPropertyTypeString;
            }
            else if ([type isEqualToString:@"@\"NSDate\""]) {
                self.type = RLMPropertyTypeDate;
            }
            else if ([type isEqualToString:@"@\"NSData\""]) {
                self.type = RLMPropertyTypeData;
            }
            else if ([type hasPrefix:@"@\"RLMArray<"]) {
                // check for array class
                Class cls = NSClassFromString([type substringWithRange:NSMakeRange(11, type.length-5)]);
                if (RLMIsSubclass(cls, RLMObject.class)) {
                    self.linkClass = cls;
                }
                else {
                    @throw [NSException exceptionWithName:@"RLMException" reason:@"No type specified for RLMArray" userInfo:nil];
                }
                self.type = RLMPropertyTypeArray;
            }
            else {
                // check if this is an RLMObject
                Class cls = NSClassFromString([type substringWithRange:NSMakeRange(2, type.length-3)]);
                if (RLMIsSubclass(cls, RLMObject.class)) {
                    self.linkClass = cls;
                    self.type = RLMPropertyTypeObject;
                }
                else {
                    @throw [NSException exceptionWithName:@"RLMException" reason:@"Encapsulated properties must descend from RLMObject" userInfo:nil];
                }
            }
            break;
        }
        default:
            self.type = RLMPropertyTypeNone;
            break;
    }
}

+(instancetype)propertyForObjectProperty:(objc_property_t)runtimeProp column:(NSUInteger)column
{
    // create new property
    RLMProperty *prop = [RLMProperty new];
    prop.name = [NSString stringWithUTF8String:property_getName(runtimeProp)];
    prop.column = column;
    
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
    
    // populate getter/setter names if generic
    if (!prop.getterName) {
        prop.getterName = prop.name;
    }
    if (!prop.setterName) {
        prop.setterName = [NSString stringWithFormat:@"set%c%@:", toupper(prop.name.UTF8String[0]), [prop.name substringFromIndex:1]];
    }
    
    return prop;
}


@end



