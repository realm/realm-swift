////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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
#import <ReactiveCocoa/ReactiveCocoa.h>

// Data models: GroupParent contains all of the data for a TableView, with a
// Group per section and an Entry per row in each section
RLM_COLLECTION_TYPE(Entry)
RLM_COLLECTION_TYPE(Group)

@interface Entry : RLMObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSDate *date;
@end

@interface Group : RLMObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) RLMArray<Entry *><Entry> *entries;
@end

@interface GroupParent : RLMObject
@property (nonatomic, strong) RLMArray<Group *><Group> *groups;
@end

@implementation Entry
// Nothing needed
@end
@implementation Group
// Nothing needed
@end
@implementation GroupParent
// Nothing needed
@end

@interface Cell : UITableViewCell
@property (nonatomic, strong) Entry *entry;
@end

@implementation Cell
- (instancetype)initWithStyle:(__unused UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (void)attach:(Entry *)entry {
    // If this is the first time this Cell is used, bind its UILabels to the
    // fields of its Entry. If it's been used before, the existing bindings
    // will continue to work
    if (self.entry == nil) {
        RAC(self.textLabel, text) = RACObserve(self, entry.title);
        RAC(self.detailTextLabel, text) = [RACObserve(self, entry.date) map:^(NSDate *date) { return date.description; }];
    }
    self.entry = entry;
}
@end

@interface TableViewController ()
@property (nonatomic, strong) GroupParent *parent;
@end

@implementation TableViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Get the singleton GroupParent object from the Realm, creating it
    // if needed. In a more complete example with more than one view, this
    // would be supplied as the data source by whatever is displaying this
    // table view
    self.parent = GroupParent.allObjects.firstObject;
    if (!self.parent) {
        self.parent = [GroupParent new];
        RLMRealm *realm = RLMRealm.defaultRealm;
        [realm transactionWithBlock:^{
            [realm addObject:self.parent];
        }];
    }

    [self setupUI];
    [self.tableView reloadData];
}

#pragma mark - UI

- (void)setupUI {
    [self.tableView registerClass:[Cell class] forCellReuseIdentifier:@"cell"];
    self.title = @"ReactiveCocoa GroupedTableView";

    RACCommand *addGroup = [[RACCommand alloc] initWithSignalBlock:^(id unused) {
        [self modifyInBackground:^(RLMArray *groups) {
            NSString *name = [NSString stringWithFormat:@"Group %d", (int)arc4random()];
            [groups addObject:[Group createInDefaultRealmWithValue:@[name, @[]]]];
        }];
        return [RACSignal empty];
    }];

    RACCommand *addEntry = [[RACCommand alloc]
                            initWithEnabled:[RACObserve(self.parent, groups) map:^(RLMArray *groups) {
                                                return @(groups.count > 0);
                                             }]
                            signalBlock:^(id unused) {
                                [self modifyInBackground:^(RLMArray *groups) {
                                    Group *group = groups[arc4random_uniform((uint32_t)groups.count)];
                                    NSString *name = [NSString stringWithFormat:@"Entry %d", (int)arc4random()];
                                    [group.entries addObject:[Entry createInDefaultRealmWithValue:@[name, NSDate.date]]];
                                }];
                                return [RACSignal empty];
                            }];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Group"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil action:nil];
    self.navigationItem.leftBarButtonItem.rac_command = addGroup;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:nil action:nil];
    self.navigationItem.rightBarButtonItem.rac_command = addEntry;

    // Subscribe to changes to the list of groups, telling the TableView to
    // insert new sections when new groups are added to the list
    @weakify(self);
    [[self.parent rac_valuesAndChangesForKeyPath:@"groups" options:0 observer:self]
     subscribeNext:^(RACTuple *info) { // tuple is value, change dictionary
         @strongify(self);
         NSDictionary *change = info.second;
         NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] intValue];
         NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
         if (indexes && kind == NSKeyValueChangeInsertion) {
             [self.tableView insertSections:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
             [self bindGroup:self.parent.groups.lastObject];
         }
         else {
             [self.tableView reloadData];
         }
     }];

     for (Group *group in self.parent.groups) {
         [self bindGroup:group];
     }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.parent.groups.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.parent.groups[section] name];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.parent.groups[section] entries].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Cell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    [cell attach:[self objectForIndexPath:indexPath]];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RLMRealm *realm = RLMRealm.defaultRealm;
        [realm beginWriteTransaction];
        [realm deleteObject:[self objectForIndexPath:indexPath]];
        [realm commitWriteTransaction];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Update the date of any row selected in the UI. The display of the date
    // in the UI is automatically updated by the binding estabished in Cell.attach
    RLMRealm *realm = RLMRealm.defaultRealm;
    [realm transactionWithBlock:^{
        [self objectForIndexPath:indexPath].date = NSDate.date;
    }];
}

#pragma - Helpers

// Get the Entry at a given index path
- (Entry *)objectForIndexPath:(NSIndexPath *)indexPath {
    return self.parent.groups[indexPath.section].entries[indexPath.row];
}

// Convert an NSIndexSet to an array of NSIndexPaths
- (NSArray<NSIndexPath *> *)indexSetToIndexPathArray:(NSIndexSet *)indexes section:(NSInteger)section {
    NSMutableArray<NSIndexPath *> *paths = [NSMutableArray arrayWithCapacity:indexes.count];
    NSUInteger index = [indexes firstIndex];
    while (index != NSNotFound) {
        [paths addObject:[NSIndexPath indexPathForRow:index inSection:section]];
        index = [indexes indexGreaterThanIndex:index];
    }
    return paths;
}

- (void)modifyInBackground:(void (^)(RLMArray *))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            GroupParent *parent = GroupParent.allObjects.firstObject;
            [parent.realm beginWriteTransaction];
            block(parent.groups);
            [parent.realm commitWriteTransaction];
        }
    });
}

// Listen for changes to the list of entries in a Group, and tell the UI to
// update when entries are added or removed
- (void)bindGroup:(Group *)group {
    @weakify(self);
    [[group rac_valuesAndChangesForKeyPath:@"entries" options:0 observer:self]
     subscribeNext:^(RACTuple *info) { // tuple is value, change dictionary
         @strongify(self);
         NSDictionary *change = info.second;
         NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] intValue];
         NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];

         if (indexes) {
             NSInteger section = [self.parent.groups indexOfObject:group];
             NSArray *paths = [self indexSetToIndexPathArray:indexes section:section];
             if (kind == NSKeyValueChangeInsertion) {
                 [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
             }
             else if (kind == NSKeyValueChangeRemoval) {
                 [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationAutomatic];
             }
             else {
                 [self.tableView reloadData];
             }
         }
         else {
             [self.tableView reloadData];
         }
     }];
}
@end
