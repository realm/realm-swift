//
//  RLMNumberTableCellView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 07/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMNumberTableCellView.h"

@interface RLMNumberTextField()

@property (nonatomic) NSNumberFormatter *numberFormatter;

@end


@implementation RLMNumberTextField

- (void)awakeFromNib {
    [super awakeFromNib];
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.hasThousandSeparators = NO;
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.numberFormatter.maximumFractionDigits = UINT16_MAX;
}

-(BOOL)becomeFirstResponder {
    if (self.number) {
        self.stringValue = [self.numberFormatter stringFromNumber:self.number];
    }
    else {
        self.stringValue = @"";
    }
    
    return [super becomeFirstResponder];
}

@end


@implementation RLMNumberTableCellView

@end




