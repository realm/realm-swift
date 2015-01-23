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

#import "RLMBRootPaneViewController.h"

@interface RLMBRootPaneViewController ()

@property (nonatomic) RLMResults *objects;

@end


@implementation RLMBRootPaneViewController

#pragma mark - Lifetime Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"RLMBRootPaneViewController did load");
}

#pragma mark - Public Methods - Update


#pragma mark - Table View Delegate


#pragma mark - Private Methods - Accessors

#pragma mark - Public Methods - Edit Action Overrides

- (void)minusRows:(NSIndexSet *)rowIndices
{
    NSMutableArray *objects = [NSMutableArray array];
    [rowIndices enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger index, BOOL *stop) {
        [objects addObject:self.objects[index]];
    }];
    [self.realmDelegate deleteObjects:objects];
}

#pragma mark - Public Methods - Getter Overrides

- (BOOL)isRootPane
{
    return YES;
}

@end