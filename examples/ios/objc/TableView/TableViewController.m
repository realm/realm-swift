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

#import "TableViewController.h"
#import <Realm/Realm.h>

// Realm model object
@interface DemoObject : RLMObject
@property NSString *title;
@property NSDate   *date;
@end

@implementation DemoObject
// None needed
@end

static NSString * const kCellID    = @"cell";
static NSString * const kTableName = @"table";

@interface TableViewController ()

@property (nonatomic, strong) RLMResults *array;
@property (nonatomic, strong) RLMNotificationToken *notification;

@end

@implementation TableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.array = [[DemoObject allObjects] sortedResultsUsingProperty:@"date" ascending:YES];
    [self setupUI];

    // Set realm notification block
    __weak typeof(self) weakSelf = self;
    self.notification = [self.array addNotificationBlock:^(RLMResults *data, NSError *error) {
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - UI

- (void)setupUI
{
    self.title = @"TableViewExample";
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:@"BG Add"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(backgroundAdd)];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(add)];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:kCellID];
    }

    DemoObject *object = self.array[indexPath.row];
    cell.textLabel.text = object.title;
    cell.detailTextLabel.text = object.date.description;

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                            forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RLMRealm *realm = RLMRealm.defaultRealm;
        [realm beginWriteTransaction];
        [realm deleteObject:self.array[indexPath.row]];
        [realm commitWriteTransaction];
    }
}

#pragma mark - Actions

- (void)backgroundAdd
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // Import many items in a background thread
    dispatch_async(queue, ^{
        // Get new realm and table since we are in a new thread
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        for (NSInteger index = 0; index < 5; index++) {
            // Add row via dictionary. Order is ignored.
            [DemoObject createInRealm:realm withValue:@{@"title": [self randomString],
                                                         @"date": [self randomDate]}];
        }
        [realm commitWriteTransaction];
    });
}

- (void)add
{
    RLMRealm *realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];
    [DemoObject createInRealm:realm withValue:@[[self randomString], [self randomDate]]];
    [realm commitWriteTransaction];
}

#pragma - Helpers

- (NSString *)randomString
{
    return [NSString stringWithFormat:@"Title %d", arc4random()];
}

- (NSDate *)randomDate
{
    return [NSDate dateWithTimeIntervalSince1970:arc4random()];
}

@end
