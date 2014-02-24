//
//  TViewController.m
//  TodoApp
//
//  Created by Morten Kjaer on 21/02/14.
//  Copyright (c) 2014 tightdb. All rights reserved.
//

#import "TViewController.h"
#import "TAppDelegate.h"

@interface TViewController ()

@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup writeTransaction:^(TightdbGroup *tnx) {
        
        // Write transactions with the shared group are possible via the provided variable binding named group.
        NSLog(@"Inside read transaction!");
        
        TightdbTable *todoTable = [tnx getTable:@"todos"];
        
        if([todoTable getColumnCount] == 0) {
            [todoTable addColumnWithType:tightdb_String andName:@"todoName"];
        }
        
        return YES; // Commit
    }];
    
    [self updateTodoCountLabel];

}

-(void)viewWillAppear:(BOOL)animated
{
    [self updateTodoCountLabel];

}


-(void) updateTodoCountLabel

{
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup readTransaction:^(TightdbGroup *tnx) {
       
        TightdbTable *todoTable = [tnx getTable:@"todos"];
        
        self.todoCountLabel.text = [NSString stringWithFormat:@"Number of todos: %zu", [todoTable count]];
        
        NSString *todoString = @"";

        for (size_t r=0;r<[todoTable count];r++) {
            todoString = [[todoString stringByAppendingString:[todoTable getString:0 ndx:r]] stringByAppendingString:@"\n"];
        }
        
        self.todos.text = todoString;
        
    }];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
