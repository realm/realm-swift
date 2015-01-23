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

#import "RLMBArrayPaneViewController.h"

@interface RLMBArrayPaneViewController ()

@property (nonatomic) RLMArray *objects;

@end


@implementation RLMBArrayPaneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"RLMBArrayPaneViewController did load");
}

#pragma mark - Public Methods - Setup

#pragma mark - Table View Delegate

#pragma mark - Public Methods - Edit Action Overrides

- (void)minusRows:(NSIndexSet *)rowIndices
{
    [self.realmDelegate removeObjectsAtIndices:rowIndices fromArray:self.objects];
}

#pragma mark - Public Methods - Getter Overrides

- (BOOL)isArrayPane
{
    return YES;
}

@end
