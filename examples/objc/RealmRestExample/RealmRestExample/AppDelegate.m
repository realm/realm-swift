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

/* This app gives a simple example of retrieving data from the foursquare REST API
   and persisting it in a Realm. To run this app, you will need to provide a foursquare
   client ID and client secret. To get these, signup at https://developer.foursquare.com/ */

#import "AppDelegate.h"
#import "Venue.h"
#import <Realm/Realm.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    UIViewController *rootVC = [[UIViewController alloc] init];
    [self.window setRootViewController:rootVC];    
    [self deleteRealmFile];
    
    #warning Provide your foursquare client ID and client secret
    NSString *clientID = @"YOUR CLIENT ID";
    NSString *clientSecret = @"YOUR CLIENT SECRET";
    
    // Get an instance of the default Realm
    RLMRealm * defaultRealm = [RLMRealm defaultRealm];
    
    // Call the API
    NSData *apiResponse = [[NSData alloc] initWithContentsOfURL:
                           [NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?near=San%@Francisco&client_id=%@&client_secret=%@&v=20140101&limit=50", @"%20", clientID, clientSecret]]];
    
    // Serialize the NSData object from the response into an NSDictionary
    NSDictionary *responseJson = [[NSJSONSerialization
                                   JSONObjectWithData:apiResponse
                                              options:kNilOptions
                                                error:nil] objectForKey:@"response"];

    // Extract the array of venues from the response
    NSArray *returnedVenues = responseJson[@"venues"];
    
    // Begin a write transaction to save to the default Realm
    [defaultRealm beginWriteTransaction];
    
    for (id venue in returnedVenues) {
        Venue *newVenue = [[Venue alloc] init];
        newVenue.foursquareID = venue[@"id"];
        newVenue.name = venue[@"name"];
        // Add the array to the default Realm
        [defaultRealm addObject:newVenue];
    }

    [defaultRealm commitWriteTransaction];
    
    // Show all the venues that were persisted
    NSLog(@"Here are all the venues persisted to the default Realm: \n\n %@",
          [[defaultRealm allObjects:Venue.className] description]);
    
    return YES;
}

- (void)deleteRealmFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"default.realm"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end
