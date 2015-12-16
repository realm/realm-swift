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

#import "RepositoriesViewController.h"
#import "RepositoryCell.h"
#import "Repository.h"

@interface RepositoriesViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UISegmentedControl *sortOrderControl;
@property (nonatomic, weak) IBOutlet UITextField *searchField;

@property (nonatomic) RLMResults *results;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://api.github.com/search/repositories"];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"q" value:@"language:objc"],
                              [NSURLQueryItem queryItemWithName:@"sort" value:@"stars"],
                              [NSURLQueryItem queryItemWithName:@"order" value:@"desc"]];
    [[[NSURLSession sharedSession] dataTaskWithURL:components.URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSError *jsonError = nil;
            NSDictionary *repositories = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            if (!jsonError) {
                NSArray *items = repositories[@"items"];

                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm transactionWithBlock:^{
                    for (NSDictionary *item in items) {
                        Repository *repository = [Repository new];
                        repository.identifier = [NSString stringWithFormat:@"%@", item[@"id"]];
                        repository.name = item[@"name"];
                        repository.avatarURL = item[@"owner"][@"avatar_url"];

                        [realm addOrUpdateObject:repository];
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadData];
                });
            } else {
                NSLog(@"%@", jsonError);
            }
        } else {
            NSLog(@"%@", error);
        }
    }] resume];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.results.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RepositoryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    Repository *repository = self.results[indexPath.item];

    cell.titleLabel.text = repository.name;

    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:repository.avatarURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *image = [UIImage imageWithData:data];
                cell.imageView.image = image;
            });
        } else {
            NSLog(@"%@", error);
        }
    }] resume];

    return cell;
}

- (void)reloadData {
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults *results;
    if (self.searchField.text.length > 0) {
        results = [Repository objectsInRealm:realm where:@"name contains[c] %@", self.searchField.text];
    } else {
        results = [Repository allObjectsInRealm:realm];
    }
    self.results = [results sortedResultsUsingProperty:@"name" ascending:self.sortOrderControl.selectedSegmentIndex == 0];

    [self.collectionView reloadData];
}

- (IBAction)valueChanged:(id)sender {
    [self reloadData];
}

- (IBAction)clearSearchField:(id)sender {
    self.searchField.text = nil;
    [self reloadData];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self reloadData];
}

@end
