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

// Model definition
@interface StringObject : RLMObject
@property NSString *stringProp;
@end

@implementation StringObject
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];

    // Realms are used to group data together
    RLMRealm *realm = [RLMRealm defaultRealm]; // Create realm pointing to default file

    // Encrypt realm file
    NSError *error = nil;
    NSDictionary *fileAttributes = @{NSFileProtectionKey: NSFileProtectionComplete};
    BOOL success = [[NSFileManager defaultManager] setAttributes:fileAttributes
                                                    ofItemAtPath:realm.path error:&error];
    if (!success) {
        NSLog(@"encryption attribute was not successfully set on realm file");
        NSLog(@"error: %@", error.localizedDescription);
    }

    // Save an object
    [realm beginWriteTransaction];
    StringObject *obj = [[StringObject alloc] init];
    obj.stringProp = @"abcd";
    [realm addObject:obj];
    [realm commitWriteTransaction];

    // Read all string objects from the encrypted realm
    NSLog(@"all string objects: %@", [StringObject allObjects]);

    return YES;
}

@end
