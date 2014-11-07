//
//  SecondViewController.m
//  SyncedRealmExample
//
//  Created by Gustaf Kugelberg on 07/11/14.
//  Copyright (c) 2014 UnfairAdvantage. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *messageField;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self messageEntered:textField.text];
    [textField resignFirstResponder];
    
    return NO;
}

-(void)messageEntered:(NSString *)message
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
