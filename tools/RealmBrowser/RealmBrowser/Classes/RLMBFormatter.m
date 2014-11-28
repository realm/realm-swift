//
//  RLMBFormatter.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 28/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBFormatter.h"

typedef NS_ENUM(int32_t, RLMBDescriptionFormat) {
    RLMBDescriptionFormatEllipsis,
    RLMBDescriptionFormatFull,
    RLMBDescriptionFormatObject
};

const NSUInteger kMaxStringCharsInObjectLink = 20;
const NSUInteger kMaxObjectCharsForTable = 200;

@interface RLMBFormatter ()

@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end


@implementation RLMBFormatter

#pragma mark - Lifetime Methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
        
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    
    return self;
}

- (NSTableCellView *)tableView:(NSTableView *)tableView cellViewForValue:(id)value type:(RLMPropertyType)type
{
    NSTableCellView *cellView;
    
    switch (type) {
        case RLMPropertyTypeArray: {
            NSTableCellView *badgeCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            NSString *string = [self printablePropertyValue:value ofType:type];
            NSDictionary *attr = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)};
            badgeCellView.textField.attributedStringValue = [[NSAttributedString alloc] initWithString:string attributes:attr];
            badgeCellView.textField.editable = NO;
            
//            badgeCellView.badge.hidden = NO;
//            badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", [(RLMArray *)propertyValue count]];
//            [badgeCellView.badge.cell setHighlightsBy:0];
//            [badgeCellView sizeToFit];
            
            cellView = badgeCellView;
            
            break;
        }
            
        case RLMPropertyTypeBool: {
            NSTableCellView *boolCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            
            boolCellView.textField.stringValue = [(NSNumber *)value boolValue] ? @"YES" : @"NO";
            
//            RLMBoolTableCellView *boolCellView = [tableView makeViewWithIdentifier:@"BoolCell" owner:self];
//            boolCellView.checkBox.state = [(NSNumber *)propertyValue boolValue] ? NSOnState : NSOffState;
//            [boolCellView.checkBox setEnabled:!self.realmIsLocked];
            
            cellView = boolCellView;
            
            break;
        }
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble: {
            NSTableCellView *numberCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            numberCellView.textField.stringValue = [self printablePropertyValue:value ofType:type];
            //            numberCellView.textField.delegate = self;
            
//            ((RLMNumberTextField *)numberCellView.textField).number = value;
//            numberCellView.textField.editable = !self.realmIsLocked;
            
            cellView = numberCellView;
            
            break;
        }
            
        case RLMPropertyTypeObject: {
            NSTableCellView *linkCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
//            linkCellView.dragType = [self dragTypeForClassName:classProperty.property.objectClassName];
//            linkCellView.delegate = self;
            
            NSString *string = [self printablePropertyValue:value ofType:type];
            NSDictionary *attr = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)};
            linkCellView.textField.attributedStringValue = [[NSAttributedString alloc] initWithString:string attributes:attr];
            linkCellView.textField.editable = NO;
            
            cellView = linkCellView;
            
            break;
        }
            // Intentional fallthrough
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeString: {
            NSTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            basicCellView.textField.stringValue = [self printablePropertyValue:value ofType:type];
//            basicCellView.textField.delegate = self;
//            basicCellView.textField.editable = !self.realmIsLocked && type != RLMPropertyTypeData;
            
            cellView = basicCellView;
            
            break;
        }
    }
    
    return cellView;
}

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType
{
    return [self printablePropertyValue:propertyValue ofType:propertyType format:RLMBDescriptionFormatFull];
}

- (NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)type format:(RLMBDescriptionFormat)format
{
    if (!propertyValue) {
        return @"";
    }
    
    switch (type) {
        case RLMPropertyTypeInt:
            self.numberFormatter.minimumFractionDigits = 0;
            
            return [self.numberFormatter stringFromNumber:(NSNumber *)propertyValue];
            
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            self.numberFormatter.minimumFractionDigits = 3;
            self.numberFormatter.maximumFractionDigits = 3;
            
            return [self.numberFormatter stringFromNumber:(NSNumber *)propertyValue];
            
        case RLMPropertyTypeString: {
            NSString *stringValue = propertyValue;
            
            if (format == RLMBDescriptionFormatEllipsis && stringValue.length > kMaxStringCharsInObjectLink) {
                stringValue = [stringValue substringToIndex:kMaxStringCharsInObjectLink - 3];
                stringValue = [stringValue stringByAppendingString:@"..."];
            }
            
            return stringValue;
        }
            
        case RLMPropertyTypeBool:
            return [(NSNumber *)propertyValue boolValue] ? @"TRUE" : @"FALSE";
            
        case RLMPropertyTypeArray: {
            RLMArray *referredArray = (RLMArray *)propertyValue;
            if (format == RLMBDescriptionFormatEllipsis) {
                return [NSString stringWithFormat:@"<%@>[%lu]", referredArray.objectClassName, referredArray.count];
            }
            
            return [NSString stringWithFormat:@"<%@>", referredArray.objectClassName];
        }
            
        case RLMPropertyTypeDate:
            return [self.dateFormatter stringFromDate:(NSDate *)propertyValue];
            
        case RLMPropertyTypeData:
            return @"<Data>";
            
        case RLMPropertyTypeAny:
            return @"<Any>";
            
        case RLMPropertyTypeObject: {
            RLMObject *referredObject = (RLMObject *)propertyValue;
            
            if (format == RLMBDescriptionFormatEllipsis) {
                return [NSString stringWithFormat:@"%@[...]", referredObject.objectSchema.className];
            }
            
            NSString *returnString;
            if (format == RLMBDescriptionFormatObject) {
                returnString = @"[";
            }
            else {
                returnString = [NSString stringWithFormat:@"%@[", referredObject.objectSchema.className];
            }
            
            for (RLMProperty *property in referredObject.objectSchema.properties) {
                id propertyValue = referredObject[property.name];
                NSString *propertyDescription = [self printablePropertyValue:propertyValue
                                                                      ofType:property.type
                                                                      format:RLMBDescriptionFormatEllipsis];
                
                if (returnString.length > kMaxObjectCharsForTable - 4) {
                    returnString = [returnString stringByAppendingFormat:@"..."];
                    break;
                }
                
                returnString = [returnString stringByAppendingFormat:@"%@, ", propertyDescription];
            }
            
            if ([returnString hasSuffix:@", "]) {
                returnString = [returnString substringToIndex:returnString.length - 2];
            }
            
            return [returnString stringByAppendingString:@"]"];
        }
    }
}

- (NSString *)typeNameForProperty:(RLMProperty *)property
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
            return @"Boolean";
        case RLMPropertyTypeString:
            return @"String";
        case RLMPropertyTypeData:
            return @"Data";
        case RLMPropertyTypeAny:
            return @"Any";
        case RLMPropertyTypeArray:
            return [NSString stringWithFormat:@"{%@}", property.objectClassName];
        case RLMPropertyTypeObject:
            return [NSString stringWithFormat:@"[%@]", property.objectClassName];
    }
}



@end
