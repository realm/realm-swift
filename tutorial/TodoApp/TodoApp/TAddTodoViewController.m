//
//  TAddTodoViewController.m
//  TodoApp
//
//  Created by Morten Kjaer on 21/02/14.
//  Copyright (c) 2014 tightdb. All rights reserved.
//

#import "TAddTodoViewController.h"
#import "TAppDelegate.h"
#import "TViewController.h"


@interface TAddTodoViewController ()

@end

@implementation TAddTodoViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    
}

- (IBAction)cancelButtonPress:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)addTodoPress:(id)sender {
    
    NSString *todo = self.todoName.text;
        
        if(todo.length > 0) {
            TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
            
            [delegate.sharedGroup writeTransaction:^(TightdbGroup *tnx) {
                
                // Write transactions with the shared group are possible via the provided variable binding named group.
                NSLog(@"Inside transaction!");
                
                TightdbTable *todoTable = [tnx getTable:@"todos"];
                
                TightdbCursor *row = [todoTable addRow];
                [row setString:self.todoName.text inColumn:0];
                        
                
                return YES; // Commit
            }];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
            [self.parentViewController viewWillAppear:YES ];
        } else {
            self.alertLabel.text = @"Enter todo";
        }
}


@end
