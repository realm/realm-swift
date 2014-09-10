//
//  RLMTextField.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 10/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RLMTextField;
@protocol RLMTextFieldDelegate <NSTextFieldDelegate>

-(void)textFieldCancelledEditing:(RLMTextField *)textField;

@end


@interface RLMTextField : NSTextField

@property (nonatomic, readonly) id<RLMTextFieldDelegate> realmDelegate;

@end
