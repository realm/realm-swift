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
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    [self.numberFormatter setHasThousandSeparators:NO];
    [self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [self.numberFormatter setMaximumFractionDigits:UINT16_MAX];
}

-(BOOL)becomeFirstResponder {
    if (self.number) {
        self.stringValue = [self.numberFormatter stringFromNumber:self.number];
    }
    
    return [super becomeFirstResponder];
}

@end


@implementation RLMNumberTableCellView

- (void)awakeFromNib {
}

- (void)viewWillDraw {
    [super viewWillDraw];
    self.textField.frame = self.bounds;
}


@end
