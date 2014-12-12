//
//  RLMBFormatter.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 28/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBViewModel.h"

#import "RLMBPaneViewController.h"
#import "RLMBBoolCellView.h"

typedef NS_ENUM(int32_t, RLMBDescriptionFormat) {
    RLMBDescriptionFormatEllipsis,
    RLMBDescriptionFormatFull,
    RLMBDescriptionFormatObject
};
NSString *const kRLMBGutterColumnIdentifier = @" #";
NSString *const kRLMBGutterCellId = @"RLMBGutterCellView";
NSString *const kRLMBBasicCellId = @"RLMBBasicCellView";
NSString *const kRLMBNumberCellId = @"RLMBNumberCellView";
NSString *const kRLMBLinkCellId = @"RLMBLinkCellView";
NSString *const kRLMBBoolCellId = @"RLMBBoolCellView";

const NSUInteger kMaxStringCharsInObjectLink = 20;
const NSUInteger kMaxObjectCharsForTable = 200;

@interface RLMBViewModel ()

@property (nonatomic, weak) RLMBPaneViewController *owner;
@property (nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end


@implementation RLMBViewModel

#pragma mark - Lifetime Methods

- (instancetype)initWithOwner:(RLMBPaneViewController *)owner
{
    self = [super init];
    if (self) {
        self.owner = owner;
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
        
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    
    return self;
}

#pragma mark - Tableview Data Methods

- (NSTableCellView *)cellViewForGutter:(NSTableView *)tableView row:(NSUInteger)row
{
    NSTableCellView *gutterCellView = [tableView makeViewWithIdentifier:kRLMBGutterCellId owner:self.owner];
    gutterCellView.textField.stringValue = @(row).stringValue;
    gutterCellView.textField.editable = NO;
    
    return gutterCellView;
}

- (NSTableCellView *)tableView:(NSTableView *)tableView cellViewForValue:(id)value type:(RLMPropertyType)type
{
    NSTableCellView *cellView;
    
    switch (type) {
        case RLMPropertyTypeArray: {
            NSTableCellView *badgeCellView = [tableView makeViewWithIdentifier:kRLMBLinkCellId owner:self.owner];
            badgeCellView.textField.stringValue = [self printablePropertyValue:value ofType:type];
            
            //            NSString *string = [self printablePropertyValue:value ofType:type];
//            NSDictionary *attr = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)};
//            badgeCellView.textField.attributedStringValue = [[NSAttributedString alloc] initWithString:string attributes:attr];
            
//            badgeCellView.badge.hidden = NO;
//            badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", [(RLMArray *)propertyValue count]];
//            [badgeCellView.badge.cell setHighlightsBy:0];
//            [badgeCellView sizeToFit];
            
            cellView = badgeCellView;
            
            break;
        }
            
        case RLMPropertyTypeBool: {
            RLMBBoolCellView *boolCellView = [tableView makeViewWithIdentifier:kRLMBBoolCellId owner:self.owner];
            boolCellView.checkBox.state = [(NSNumber *)value boolValue] ? NSOnState : NSOffState;
            
            cellView = boolCellView;
            
            break;
        }
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble: {
            NSTableCellView *numberCellView = [tableView makeViewWithIdentifier:kRLMBNumberCellId owner:self.owner];
            numberCellView.textField.stringValue = [self printablePropertyValue:value ofType:type];
//            ((RLMNumberTextField *)numberCellView.textField).number = value;
            
            cellView = numberCellView;
            
            break;
        }
            
        case RLMPropertyTypeObject: {
            NSTableCellView *linkCellView = [tableView makeViewWithIdentifier:kRLMBLinkCellId owner:self.owner];
//            linkCellView.dragType = [self dragTypeForClassName:classProperty.property.objectClassName];
//            linkCellView.delegate = self;
            
            NSString *string = [self printablePropertyValue:value ofType:type];
            NSDictionary *attr = @{NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)};
            linkCellView.textField.attributedStringValue = [[NSAttributedString alloc] initWithString:string attributes:attr];
            
            cellView = linkCellView;
            
            break;
        }
            // Intentional fallthrough
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeString: {
            NSTableCellView *basicCellView = [tableView makeViewWithIdentifier:kRLMBBasicCellId owner:self.owner];
            basicCellView.textField.stringValue = [self printablePropertyValue:value ofType:type];

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
