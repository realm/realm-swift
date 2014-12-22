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

#import "RLMBViewModel.h"
#import "RLMBPaneViewController.h"

const NSUInteger kMaxStringCharsInObjectLink = 20;
const NSUInteger kMaxObjectCharsForTable = 200;

@interface RLMBViewModel ()

@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end


@implementation RLMBViewModel

#pragma mark - Lifetime Methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
        
        self.numberFormatter = [[NSNumberFormatter alloc] init];
    }
    
    return self;
}

#pragma mark - Public Methods

- (NSString *)printablePropertyValue:(id)propertyValue type:(RLMPropertyType)type
{
    switch (type) {
        case RLMPropertyTypeBool:
            return [(NSNumber *)propertyValue boolValue] ? @"TRUE" : @"FALSE";
            
        case RLMPropertyTypeInt:
            self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            self.numberFormatter.minimumFractionDigits = 0;
            return [self.numberFormatter stringFromNumber:(NSNumber *)propertyValue];

        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            self.numberFormatter.minimumFractionDigits = 3;
            self.numberFormatter.maximumFractionDigits = 3;
            return [self.numberFormatter stringFromNumber:(NSNumber *)propertyValue];

        case RLMPropertyTypeData:
            return @"(Data)";

        case RLMPropertyTypeAny:
            return @"(Any)";
    
        case RLMPropertyTypeDate:
            return [self.dateFormatter stringFromDate:(NSDate *)propertyValue];

        case RLMPropertyTypeString:
            return [self shortenString:propertyValue];
            
        case RLMPropertyTypeArray:
        case RLMPropertyTypeObject:
            return nil;
    }
}

- (NSString *)printableArray:(RLMArray *)array
{
    NSMutableString *description = [NSMutableString string];
    for (RLMObject *object in array) {
        if (description.length > 0) {
            [description appendString:@", "];
        } else if (description.length > kMaxStringCharsInObjectLink){
            break;
        }
        [description appendString:[self printableObject:object]];
    }
    
    return description;
}

- (NSString *)printableObject:(RLMObject *)object
{
    if (!object) {
        return @"";
    }
    
    RLMProperty *property = object.objectSchema.primaryKeyProperty ?: object.objectSchema.properties.firstObject;
    id value = object[property.name];
    
    if (property.type == RLMPropertyTypeObject) {
        RLMObject *linkedObject = value;
        return [NSString stringWithFormat:@"<%@>", linkedObject.objectSchema.className];
    }
    else if (property.type == RLMPropertyTypeArray) {
        RLMArray *linkedArray = value;
        return [NSString stringWithFormat:@"[%@]", linkedArray.objectClassName];
    }
    
    return [self printablePropertyValue:value type:property.type];
}


- (NSString *)editablePropertyValue:(id)propertyValue type:(RLMPropertyType)type
{
    switch (type) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            self.numberFormatter.numberStyle = NSNumberFormatterNoStyle;
            self.numberFormatter.maximumFractionDigits = UINT16_MAX;
            self.numberFormatter.minimumFractionDigits = 0;

            return [self.numberFormatter stringFromNumber:(NSNumber *)propertyValue];
            
        case RLMPropertyTypeDate:
            return [self.dateFormatter stringFromDate:(NSDate *)propertyValue];
            
        case RLMPropertyTypeString:
            return propertyValue;
            
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeObject:
            return nil;
    }
}

- (id)valueForString:(NSString *)string type:(RLMPropertyType)type
{
    switch (type) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            self.numberFormatter.numberStyle = NSNumberFormatterNoStyle;
            self.numberFormatter.maximumFractionDigits = UINT16_MAX;
            self.numberFormatter.minimumFractionDigits = 0;
            
            return [self.numberFormatter numberFromString:string];
            
        case RLMPropertyTypeDate:
            return [self.dateFormatter dateFromString:string];
            
        case RLMPropertyTypeString:
            return string;
            
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeObject:
            return nil;
    }
}

+ (NSAttributedString *)headerStringForProperty:(RLMProperty *)property
{
    NSString *typeName = [self typeNameForProperty:property];
    
    NSString *stringValue = [NSString stringWithFormat:@"%@: %@", property.name, typeName];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:stringValue];
    NSRange firstStringRange = NSMakeRange(0, property.name.length + 1);
    NSRange secondStringRange = NSMakeRange(stringValue.length - typeName.length, typeName.length);
    [attributedString addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:12.0] range:firstStringRange];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:secondStringRange];
    
    return attributedString;
}

+ (NSString *)typeNameForProperty:(RLMProperty *)property
{
    switch (property.type) {
        case RLMPropertyTypeInt:
            return @"Int";
        case RLMPropertyTypeFloat:
            return @"Float";
        case RLMPropertyTypeDouble:
            return @"Float";
        case RLMPropertyTypeDate:
            return @"Date";
        case RLMPropertyTypeBool:
            return @"Bool";
        case RLMPropertyTypeString:
            return @"String";
        case RLMPropertyTypeData:
            return @"Data";
        case RLMPropertyTypeAny:
            return @"Any";
        case RLMPropertyTypeObject:
            return [NSString stringWithFormat:@"<%@>", property.objectClassName];
        case RLMPropertyTypeArray:
            return [NSString stringWithFormat:@"[%@]", property.objectClassName];
    }
}

#pragma mark - Private Methods

- (NSString *)shortenString:(NSString *)string
{
    if (string.length > kMaxStringCharsInObjectLink) {
        string = [string substringToIndex:kMaxStringCharsInObjectLink - 3];
        string = [string stringByAppendingString:@"..."];
    }
    
    return string;
}

@end
