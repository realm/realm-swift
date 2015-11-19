//
//  PlacesViewController.m
//  PreloadedData
//
//  Created by Katsumi Kishikawa on 11/20/15.
//  Copyright © 2015 Realm. All rights reserved.
//

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

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *seedFilePath = [mainBundle pathForResource:@"Places" ofType:@"realm"];
    config.path = seedFilePath;

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
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults *results;
    if (self.searchField.text.length > 0) {
        results = [Place objectsInRealm:realm where:@"postalCode beginswith %@", self.searchField.text];
    } else {
        results = [Place allObjectsInRealm:realm];
    }
    self.results = [results sortedResultsUsingProperty:@"postalCode" ascending:YES];

    [self.tableView reloadData];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self reloadData];
}

@end
