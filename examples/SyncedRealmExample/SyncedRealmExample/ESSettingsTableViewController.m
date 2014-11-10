//
//  ESSettingsTableViewController.m
//  SyncedRealmExample
//
//  Created by Gustaf Kugelberg on 07/11/14.
//  Copyright (c) 2014 UnfairAdvantage. All rights reserved.
//

#import "ESSettingsTableViewController.h"
#import <Realm/Realm.h>

@interface ESSettingsTableViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *hostField;
@property (weak, nonatomic) IBOutlet UITextField *portField;
@property (weak, nonatomic) IBOutlet UITextField *realmField;

@property (nonatomic) NSString *urlScheme;

@property (nonatomic) RLMRealm *realm;

@end

@implementation ESSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    if (realm.serverBaseURL) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithString:realm.serverBaseURL];
        
        self.urlScheme = [components scheme];
        self.hostField.placeholder = [components host];
        self.portField.placeholder = [[components port] stringValue];
    }
    
    //    if (realm.name) {
    //        self.realmField.placeholder = realm.name;
    //    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

-(void)updateSettings
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.host = self.hostField.text.length > 0 ? self.hostField.text : self.hostField.placeholder;
    NSString *port = self.portField.text.length > 0 ? self.portField.text : self.portField.placeholder;
    components.port = @([port integerValue]);
    components.scheme = self.urlScheme;
    
    self.realm.serverBaseURL = components.string;
    
    //        self.realm.name = self.realmField.text;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
