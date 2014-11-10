//
//  SecondViewController.m
//  SyncedRealmExample
//
//  Created by Gustaf Kugelberg on 07/11/14.
//  Copyright (c) 2014 UnfairAdvantage. All rights reserved.
//

#import "SecondViewController.h"
#import <Realm/Realm.h>

@interface ESMessage : RLMObject

@property NSDate *timestamp;
@property NSString *content;

@end


@implementation ESMessage

@end


@interface SecondViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *messageField;
@property (nonatomic, readonly) ESMessage *message;

@property (nonatomic) RLMNotificationToken *notificationToken;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    RLMRealm *realm = [RLMRealm defaultRealm];
    self.notificationToken = [realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        [self messageChanged];
    }];
    
    [realm beginWriteTransaction];
    if (!self.message) {
        ESMessage *newMessage = [[ESMessage alloc] initWithObject:@[[NSDate date], @"Message"]];
        [realm addObject:newMessage];
    }
    [realm commitWriteTransaction];

    [self messageChanged];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"textField should return");

    [self messageEntered:textField.text];
    [textField resignFirstResponder];
    
    return NO;
}

-(void)messageEntered:(NSString *)content
{
    NSLog(@"message entered: %@", content);

    ESMessage *message = self.message;

    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    message.timestamp = [NSDate date];
    message.content = content;
    [realm commitWriteTransaction];
}

-(void)messageChanged
{
    NSLog(@"message changed: %@", self.message.content);
    self.messageField.text = self.message.content;
}

-(ESMessage *)message
{
    return [ESMessage allObjects].firstObject;
}

- (void)dealloc
{
    [[RLMRealm defaultRealm] removeNotification:self.notificationToken];
}

@end
