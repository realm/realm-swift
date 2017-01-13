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

#import "PlacesViewController.h"
#import "Place.h"

@interface PlacesViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *searchField;
@property (nonatomic) RLMResults *results;

@end

@implementation PlacesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.readOnly = YES;
    config.fileURL = [[NSBundle mainBundle] URLForResource:@"Places" withExtension:@"realm"];
    [RLMRealmConfiguration setDefaultConfiguration:config];

    [self reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    Place *place = self.results[indexPath.row];

    cell.textLabel.text = place.postalCode;
    if (place.county) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@, %@", place.placeName, place.state, place.county];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", place.placeName, place.state];
    }

    return cell;
}

- (void)reloadData {
    self.results = [Place allObjects];
    if (self.searchField.text.length > 0) {
        self.results = [self.results objectsWhere:@"postalCode beginswith %@", self.searchField.text];
    }
    self.results = [self.results sortedResultsUsingKeyPath:@"postalCode" ascending:YES];

    [self.tableView reloadData];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self reloadData];
}

@end
