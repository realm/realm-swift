//
//  RLMTextField.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 10/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMTextField.h"

@implementation RLMTextField

-(void)awakeFromNib
{
    [super awakeFromNib];
}

-(BOOL)resignFirstResponder
{
    [self.realmDelegate textFieldCancelledEditing:self];
    
    return YES;
}

-(id<RLMTextFieldDelegate>)realmDelegate
{
    return (id<RLMTextFieldDelegate>)self.delegate;
}

@end
