//
//  TAddTodoViewController.h
//  TodoApp
//
//  Created by Morten Kjaer on 21/02/14.
//  Copyright (c) 2014 tightdb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TAddTodoViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *todoName;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;

@end
