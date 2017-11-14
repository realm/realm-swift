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

#import "AppDelegate.h"
#import <Realm/Realm.h>

// Define your models
@interface Dog : RLMObject
@property NSString *name;
@property NSInteger age;
@end

@implementation Dog
// No need for implementation
@end

RLM_ARRAY_TYPE(Dog)

@interface Person : RLMObject
@property NSString      *name;
@property RLMArray<Dog> *dogs;
@end

@implementation Person
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];

    [[NSFileManager defaultManager] removeItemAtURL:[RLMRealmConfiguration defaultConfiguration].fileURL error:nil];

    // Create a standalone object
    Dog *mydog = [[Dog alloc] init];

    // Set & read properties
    mydog.name = @"Rex";
    mydog.age = 9;
    NSLog(@"Name of dog: %@", mydog.name);

    // Realms are used to group data together
    RLMRealm *realm = [RLMRealm defaultRealm]; // Create realm pointing to default file

    // Save your object
    [realm beginWriteTransaction];
    [realm addObject:mydog];
    [realm commitWriteTransaction];

    // Query
    RLMResults *results = [Dog objectsInRealm:realm where:@"name contains 'x'"];

    // Queries are chainable!
    RLMResults *results2 = [results objectsWhere:@"age > 8"];
    NSLog(@"Number of dogs: %li", (unsigned long)results2.count);

    // Link objects
    Person *person = [[Person alloc] init];
    person.name = @"Tim";
    [person.dogs addObject:mydog];

    [realm beginWriteTransaction];
    [realm addObject:person];
    [realm commitWriteTransaction];

    // Multi-threading
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            RLMRealm *otherRealm = [RLMRealm defaultRealm];
            RLMResults *otherResults = [Dog objectsInRealm:otherRealm where:@"name contains 'Rex'"];
            NSLog(@"Number of dogs: %li", (unsigned long)otherResults.count);
        }
    });

    return YES;
}

@end
