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
#import "DataModels.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];

    // define a migration block
    // you can define this inline, but we will reuse this to migrate realm files from multiple versions
    // to the most current version of our data model
    RLMMigrationBlock migrationBlock = ^NSUInteger(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        if (oldSchemaVersion < 1) {
            [migration enumerateObjects:Person.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                if (oldSchemaVersion < 1) {
                    // combine name fields into a single field
                    newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@", oldObject[@"firstName"], oldObject[@"lastName"]];
                }
            }];
        }
        if (oldSchemaVersion < 2) {
            [migration enumerateObjects:Person.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                // give JP a dog
                if ([newObject[@"fullName"] isEqualToString:@"JP McDonald"]) {
                    Pet *jpsDog = [[Pet alloc] initWithObject:@[@"Jimbo", @(AnimalTypeDog)]];
                    [newObject[@"pets"] addObject:jpsDog];
                }
            }];
        }
        if (oldSchemaVersion < 3) {
            [migration enumerateObjects:Pet.className block:^(RLMObject *oldObject, RLMObject *newObject) {
                // convert type string to type enum if we have outdated Pet object
                if (oldObject && oldObject.objectSchema[@"type"].type == RLMPropertyTypeString) {
                    newObject[@"type"] = @([Pet animalTypeForString:oldObject[@"type"]]);
                }
            }];
        }

        // return the new schema version
        return 3;
    };

    //
    // Migrate the default realm over multiple data model versions
    //
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = paths[0];
    NSString *defaultRealmPath = [docsDir stringByAppendingPathComponent:@"default.realm"];

    // copy over old data file for v0 data model
    NSString *v0Path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"default-v0.realm"];
    [[NSFileManager defaultManager] removeItemAtPath:defaultRealmPath error:nil];;
    [[NSFileManager defaultManager] copyItemAtPath:v0Path toPath:defaultRealmPath error:nil];

    // opening an outdated realm file without a migration with throw
    @try {
        [RLMRealm realmWithPath:v0Path];
    }
    @catch (NSException *exception) {
        NSLog(@"Trying to open an outdated realm without migrating threw an exception.");
    }

    // migrate default realm at v0 data model to the current version
    [RLMRealm migrateDefaultRealmWithBlock:migrationBlock];

    // print out all migrated objects in the default realm
    NSLog(@"Migrated objects in the default Realm: %@", [[Person allObjects] description]);

    //
    // Migrate a realms at a custom paths
    //
    NSString *v1Path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"default-v1.realm"];
    NSString *v2Path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"default-v2.realm"];
    NSString *realmv1Path = [docsDir stringByAppendingPathComponent:@"default-v1.realm"];
    NSString *realmv2Path = [docsDir stringByAppendingPathComponent:@"default-v2.realm"];
    [[NSFileManager defaultManager] removeItemAtPath:realmv1Path error:nil];;
    [[NSFileManager defaultManager] copyItemAtPath:v1Path toPath:realmv1Path error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:realmv2Path error:nil];;
    [[NSFileManager defaultManager] copyItemAtPath:v2Path toPath:realmv2Path error:nil];

    // migrate realms at custom paths
    [RLMRealm migrateRealmAtPath:realmv1Path withBlock:migrationBlock];
    [RLMRealm migrateRealmAtPath:realmv2Path withBlock:migrationBlock];

    // print out all migrated objects in the migrated realms
    RLMRealm *realmv1 = [RLMRealm realmWithPath:realmv1Path];
    NSLog(@"Migrated objects in the Realm migrated from v1: %@", [[Person allObjectsInRealm:realmv1] description]);
    RLMRealm *realmv2 = [RLMRealm realmWithPath:realmv2Path];
    NSLog(@"Migrated objects in the Realm migrated from v2: %@", [[Person allObjectsInRealm:realmv2] description]);

    return YES;
}

@end
