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

#import <Realm/Realm.h>
#import "InterfaceController.h"

@interface Counter: RLMObject
@property int count;
@end
@implementation Counter
@end

@interface InterfaceController ()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *button;
@property (nonatomic, strong) Counter *counter;
@property (nonatomic, strong) RLMNotificationToken *token;
@end

@implementation InterfaceController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.counter = [[Counter alloc] init];
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm addObject:self.counter];
        }];
    }
    return self;
}

- (IBAction)increment {
    [self.counter.realm transactionWithBlock:^{
        self.counter.count++;
    }];
}

- (void)willActivate {
    [super willActivate];
    self.token = [self.counter.realm addNotificationBlock:^(NSString * _Nonnull notification, RLMRealm * _Nonnull realm) {
        [self.button setTitle:[NSString stringWithFormat:@"%@", @(self.counter.count)]];
    }];
}

- (void)didDeactivate {
    [self.token invalidate];
    [super didDeactivate];
}

@end
