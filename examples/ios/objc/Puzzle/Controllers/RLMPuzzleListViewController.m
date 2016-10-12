////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMPuzzleListViewController.h"
#import "RLMPuzzle.h"

@interface RLMPuzzleListViewController () 

@property (nonatomic, strong) RLMResults *puzzles;

- (void)cancelButtonTapped:(id)sender;

@end

@implementation RLMPuzzleListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Puzzles";
    self.puzzles = [RLMPuzzle allObjects];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.puzzles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
 
    RLMPuzzle *puzzle = self.puzzles[indexPath.row];
    cell.textLabel.text = puzzle.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    RLMPuzzle *puzzle = self.puzzles[indexPath.row];
    if (self.puzzleChosenHandler)
        self.puzzleChosenHandler(puzzle);
}

- (void)cancelButtonTapped:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
