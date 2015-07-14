//
//  RLMPuzzleListViewController.m
//  RealmExamples
//
//  Created by Tim Oliver on 7/14/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import "RLMPuzzleListViewController.h"
#import <Realm/Realm.h>
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
