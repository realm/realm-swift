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
@property NSString *phoneNumber;
@property NSDate   *date;
@property NSString *contactName;
@end

@implementation DemoObject
// None needed
@end

static NSString * const kCellID    = @"cell";
static NSString * const kTableName = @"table";

@interface TableViewController ()

@property (nonatomic, strong) RLMSectionedResults<NSString *, DemoObject *> *sectionedResults;
@property (nonatomic, strong) RLMNotificationToken *notification;

@end

@implementation TableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Section Titles
    [self setupUI];

    self.sectionedResults = [[DemoObject allObjects] sectionedResultsSortedUsingKeyPath:@"contactName"
                                                                              ascending:YES
                                                                               keyBlock:^(DemoObject *object) {
        return [object.contactName substringToIndex:1];
    }];

    // Set realm notification block
    __weak typeof(self) weakSelf = self;
    self.notification = [self.sectionedResults addNotificationBlock:^(RLMSectionedResults<NSString *, DemoObject *> *col,
                                                                      RLMSectionedResultsChange *changes) {
        if (changes) {
            [weakSelf.tableView performBatchUpdates:^{
                [weakSelf.tableView deleteRowsAtIndexPaths:changes.deletions withRowAnimation:UITableViewRowAnimationAutomatic];
                [weakSelf.tableView insertRowsAtIndexPaths:changes.insertions withRowAnimation:UITableViewRowAnimationAutomatic];
                [weakSelf.tableView reloadRowsAtIndexPaths:changes.modifications withRowAnimation:UITableViewRowAnimationAutomatic];
                [weakSelf.tableView insertSections:changes.sectionsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
                [weakSelf.tableView deleteSections:changes.sectionsToRemove withRowAnimation:UITableViewRowAnimationAutomatic];
            } completion:^(BOOL finished) {
                // Noop
            }];
        }
    }];

    [self.tableView reloadData];
}

#pragma mark - UI

- (void)setupUI
{
    self.title = @"GroupedTableView";
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionedResults.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.sectionedResults[section].key;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sectionedResults.allKeys;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sectionedResults[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:kCellID];
    }

    DemoObject *object = self.sectionedResults[indexPath.section][indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", object.contactName, object.phoneNumber];
    cell.detailTextLabel.text = object.date.description;

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RLMRealm *realm = RLMRealm.defaultRealm;
        [realm beginWriteTransaction];
        DemoObject *object = self.sectionedResults[indexPath.section][indexPath.row];
        [realm deleteObject:object];
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
        @autoreleasepool {
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            for (NSInteger index = 0; index < 5; index++) {
                // Add row via dictionary. Order is ignored.
                [DemoObject createInRealm:realm withValue:@{@"phoneNumber": [self randomContactInfo],
                                                             @"date": [NSDate date],
                                                             @"contactName": [self randomContactName]}];
            }
            [realm commitWriteTransaction];
        }
    });
}

- (void)add
{
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [DemoObject createInDefaultRealmWithValue:@[[self randomContactInfo], [NSDate date], [self randomContactName]]];
    }];
}

#pragma - Helpers

- (NSInteger)randomNumberBetween:(NSInteger)min maxNumber:(NSInteger)max
{
    return min + arc4random_uniform((uint32_t)(max - min + 1));
}

- (NSString *)randomContactInfo
{
    NSInteger rand1 = [self randomNumberBetween:0 maxNumber:9];
    NSInteger rand2 = [self randomNumberBetween:0 maxNumber:9];
    NSInteger rand3 = [self randomNumberBetween:0 maxNumber:9];
    return [NSString stringWithFormat:@"555-55%ld-%ld%ld55", (long)rand1, rand2, rand3];
}

- (NSString *)randomContactName
{
    NSArray *names = @[@"John", @"Mary", @"Fred", @"Sarah", @"Sally", @"James"];
    return [names objectAtIndex:arc4random()%[names count]];
}

@end
