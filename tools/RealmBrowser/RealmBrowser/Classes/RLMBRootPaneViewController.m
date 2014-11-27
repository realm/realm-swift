//
//  RLMBRootPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 27/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBRootPaneViewController.h"
#import "RLMBHeaders_Private.h"

@interface RLMBRootPaneViewController ()

@property (nonatomic) RLMObjectSchema *objectSchema;

@end

@implementation RLMBRootPaneViewController

#pragma mark - Lifetime Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - Public Methods

- (void)updateWithRealm:(RLMRealm *)realm objectSchema:(RLMObjectSchema *)objectSchema
{
    self.objects = [realm allObjects:objectSchema.className];
    self.classNameLabel.stringValue = objectSchema.className;
    [self.tableView reloadData];
    
    self.objectSchema = objectSchema;
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.objects.count;
}

#pragma mark - Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"Standard" owner:self];
    RLMObject *object = self.objects[row];
    
    RLMProperty *prop = self.objectSchema.properties[1];
    
    cellView.textField.stringValue = [object valueForKey:prop.name];
    
    return cellView;
}

#pragma mark - Private Methods - Accessors

@end
