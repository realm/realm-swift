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

#import "ChatViewController.h"
#import "UIColor+ChatColors.h"
#import "Message.h"
#import "ChatTextField.h"
#import <Realm/Realm.h>

@interface ChatViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet ChatTextField *messageField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageFieldMargin;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *closeButtonWidth;

@property (nonatomic, strong) RLMResults *messages;
@property (nonatomic) RLMNotificationToken *notificationToken;
@property (nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) NSString *vendorid;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.vendorid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.contentInset = UIEdgeInsetsMake(70.0, 0.0, 0.0, 0.0);

    self.notificationToken = [[RLMRealm defaultRealm] addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        [self updateStream];
    }];

    [self updateStream];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [self setCloseButtonVisibility:NO];
}

# pragma mark - Table View Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.messages.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = self.messages[indexPath.section];

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

# pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self messageEntered:textField.text];

    return NO;
}

# pragma mark - Action Methods

- (IBAction)closeTextField:(UIButton *)sender
{
    [self.messageField resignFirstResponder];
}

# pragma mark - Private Methods

- (void)updateStream
{
    self.messages = [Message allObjects];
    [self.tableView reloadData];

    NSInteger sectionCount = [self.tableView numberOfSections];
    if (sectionCount > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionCount - 1];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)messageEntered:(NSString *)content
{
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [Message createInDefaultRealmWithObject:@[[NSDate date], content, self.vendorid]];
    }];
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
    [self setCloseButtonVisibility:(newHeight > 0.0)];

    [self.view setNeedsUpdateConstraints];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

- (void)setCloseButtonVisibility:(BOOL)on
{
    self.closeButtonWidth.constant = on ? 60 : 0;
    self.closeButton.titleLabel.alpha = on;
}

@end
