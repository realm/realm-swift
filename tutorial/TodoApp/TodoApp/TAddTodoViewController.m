//
//  TAddTodoViewController.m
//  TodoApp
//
//  Created by Morten Kjaer on 21/02/14.
//  Copyright (c) 2014 tightdb. All rights reserved.
//

#import "TAddTodoViewController.h"
#import "TAppDelegate.h"
#import <Tightdb/Tightdb.h>


@interface TAddTodoViewController ()

@end

@implementation TAddTodoViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Auto select input field when modal is shown
    [self.todoName becomeFirstResponder];
}

// Close modal when user presses Cancel button
- (IBAction)cancelButtonPress:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Add todo to db, when user presses Add button
- (IBAction)addTodoPress:(id)sender {
    
    NSString *todo = self.todoName.text;
    
    // Only add to db if todoName has been entered
    if(todo.length > 0) {
        
        TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
            
        bool success = [delegate.sharedGroup writeWithBlock:^(TightdbGroup *tnx) {
                
            TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
                
            TightdbCursor *row = [todoTable addEmptyRow];
            [row setString:self.todoName.text inColumn:0];
                
            return YES; // Commit
        } withError:nil];
        
        if (success) {
            // Close modal
            [self dismissViewControllerAnimated:YES completion:nil];
            
            // Make parent reload the todos from the db
            [self.parentViewController viewWillAppear:YES ];
        }
        
    } else {
        // If no name has been entered, show an error alert
        self.alertLabel.text = @"Enter name for todo";
    }
}


@end
