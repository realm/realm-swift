//
//  SecondViewController.m
//  SyncedRealmExample
//
//  Created by Gustaf Kugelberg on 07/11/14.
//  Copyright (c) 2014 UnfairAdvantage. All rights reserved.
//

#import "SecondViewController.h"
#import "UIColor+ChatColors.h"
#import <Realm/Realm.h>

@interface ESChatMessage : RLMObject

@property NSDate *timestamp;
@property NSString *content;
@property NSString *sender;

@end
RLM_ARRAY_TYPE(ESChatMessage)


@implementation ESChatMessage
@end


@interface ESChatRoom : RLMObject

@property RLMArray<ESChatMessage> *messages;

@end


@implementation ESChatRoom

@end


@interface ESTextField : UITextField
@end

@implementation ESTextField

-(CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 15.0, 0.0);
}

-(CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 15.0, 0.0);
}

@end


@interface SecondViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet ESTextField *messageField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageFieldMargin;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *closeButtonWidth;

@property (nonatomic, readonly) ESChatRoom *chatRoom;
@property (nonatomic) RLMNotificationToken *notificationToken;
@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) NSString *vendorid;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    if (!self.chatRoom) {
        ESChatRoom *chatRoom = [[ESChatRoom alloc] initWithObject:@[@[]]];
        [realm addObject:chatRoom];
    }
    [realm commitWriteTransaction];
    
    self.notificationToken = [realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        [self updateStream];
    }];
    
    [self updateStream];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [self toggleCloseButtonVisibility:NO];
}

# pragma mark - Table View Datasource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.chatRoom.messages.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ESChatMessage *message = self.chatRoom.messages[indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PinkCell"];
    cell.clipsToBounds = YES;
    cell.textLabel.text = message.content;
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:message.timestamp];
    
    if ([message.sender isEqualToString:self.vendorid]) {
        cell.contentView.backgroundColor = [UIColor lightGrayColor];
    }
    else {
        cell.contentView.backgroundColor = [UIColor pinkColor];
    }

    return cell;
}

# pragma mark - Table View Delegate

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 5.0;
}

# pragma mark - Text Field Delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self messageEntered:textField.text];
    
    return NO;
}

# pragma mark - Action Methods

-(IBAction)closeTextField:(UIButton *)sender
{
    [self.messageField resignFirstResponder];
}

# pragma mark - Private Methods

-(void)updateStream
{
    [self.tableView reloadData];
    
    NSInteger sectionCount = [self.tableView numberOfSections];
    if (sectionCount > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionCount - 1];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

-(void)messageEntered:(NSString *)content
{
    ESChatMessage *message = [[ESChatMessage alloc] init];
    message.timestamp = [NSDate date];
    message.content = content;
    message.sender = self.vendorid;

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [self.chatRoom.messages addObject:message];
    [realm commitWriteTransaction];
    
    self.messageField.text = @"";
}

# pragma mark - Private Methods - Keyboard Handling

- (void)keyboardWillChange:(NSNotification *)notification {
    CGRect initialRect = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat initialHeight = self.view.frame.size.height - [self.view convertRect:initialRect fromView:nil].origin.y;
    
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat newHeight = self.view.frame.size.height - [self.view convertRect:keyboardRect fromView:nil].origin.y;
    
    CGPoint offset = self.tableView.contentOffset;
    offset.y += newHeight - initialHeight;
    self.tableView.contentOffset = offset;
    
    self.messageFieldMargin.constant = newHeight;
    [self toggleCloseButtonVisibility:(newHeight > 0.0)];
    
    [self.view setNeedsUpdateConstraints];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

-(void)toggleCloseButtonVisibility:(BOOL)on
{
    if (on) {
        self.closeButtonWidth.constant = 60.0;
        self.closeButton.titleLabel.alpha = 1.0;
    }
    else {
        self.closeButtonWidth.constant = 0.0;
        self.closeButton.titleLabel.alpha = 0.0;
    }
}

# pragma mark - Convenience Methods

-(ESChatRoom *)chatRoom
{
    return [ESChatRoom allObjects].firstObject;
}

-(NSString *)vendorid
{
    if (!_vendorid) {
        _vendorid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return _vendorid;
}

# pragma mark - Other methods

-(void)dealloc
{
    [[RLMRealm defaultRealm] removeNotification:self.notificationToken];
}

@end
