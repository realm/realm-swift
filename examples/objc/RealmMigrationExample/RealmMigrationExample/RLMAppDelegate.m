//
//  RLMAppDelegate.m
//  RealmMigrationExample
//
//  Created by Ari Lazier on 6/26/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMAppDelegate.h"
#import <Realm/Realm.h>
#import "DataModels.h"

@implementation RLMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // define a migration block
    // you can define this inline, but we will reuse this to migrate realm files from multiple versions
    // to the most current version of our data model
    RLMMigrationBlock migrationBlock = ^NSUInteger(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        [migration enumerateObjectsWithClass:Person.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            if (oldSchemaVersion < 1) {
                // combine name fields into a single field
                newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@", oldObject[@"firstName"], oldObject[@"lastName"]];
            }
            if (oldSchemaVersion < 2) {
                // give JP a dog
                if ([newObject[@"fullName"] isEqualToString:@"JP McDonald"]) {
                    Pet *jpsDog = [[Pet alloc] initWithObject:@[@"Jimbo", @(AnimalTypeDog)]];
                    [newObject[@"pets"] addObject:jpsDog];
                }
            }
        }];
        [migration enumerateObjectsWithClass:Pet.className block:^(RLMObject *oldObject, RLMObject *newObject) {
            if (oldSchemaVersion < 3) {
                // convert type string to type enum
                newObject[@"type"] = @([Pet animalTypeForString:oldObject[@"type"]]);
            }
        }];
        return 3;
    };
    
    //
    // Migrate the default realm over multiple data model versions
    //
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
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
    [RLMRealm applyMigrationBlock:migrationBlock error:nil];
    
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
    
    // migrate the realm at v2DocsPath
    [RLMRealm applyMigrationBlock:migrationBlock atPath:realmv1Path error:nil];
    [RLMRealm applyMigrationBlock:migrationBlock atPath:realmv2Path error:nil];

    // print out all migrated objects in one of the migrated realm - all migrated realms now have the same data
    RLMRealm *realm = [RLMRealm realmWithPath:realmv1Path];
    NSLog(@"Migrated objects in the migrated Realm: %@", [[realm allObjects:Person.className] description]);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
