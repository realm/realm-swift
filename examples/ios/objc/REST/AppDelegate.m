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

// This app gives a simple example of retrieving data from the foursquare REST API
// and persisting it in a Realm. To run this app, you will need to provide a foursquare
// client ID and client secret. To get these, signup at https://developer.foursquare.com/

#import "AppDelegate.h"
#import "Venue.h"
#import <Realm/Realm.h>

#error Provide your foursquare client ID and client secret
NSString *clientID = @"YOUR CLIENT ID";
NSString *clientSecret = @"YOUR CLIENT SECRET";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];

    // Ensure we start with an empty database
    [[NSFileManager defaultManager] removeItemAtPath:[RLMRealmConfiguration defaultConfiguration].path error:nil];

    // Query Foursquare API
    NSDictionary *foursquareVenues = [self getFoursquareVenues];

    // Persist the results to Realm
    [self persistToDefaultRealm:foursquareVenues];

    return YES;
}

-(NSDictionary*)getFoursquareVenues
{
    // Call the foursquare API - here we use an NSData method for our API request,
    // but you could use anything that will allow you to call the API and serialize
    // the response as an NSDictionary or NSArray
    NSData *apiResponse = [[NSData alloc] initWithContentsOfURL:
                           [NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?near=San%@Francisco&client_id=%@&client_secret=%@&v=20140101&limit=50", @"%20", clientID, clientSecret]]];

    // Serialize the NSData object from the response into an NSDictionary
    NSDictionary *serializedResponse = [[NSJSONSerialization JSONObjectWithData:apiResponse
                                                                        options:kNilOptions
                                                                          error:nil]
                                        objectForKey:@"response"];

    // Extract the venues from the response as an NSDictionary
    return serializedResponse[@"venues"];
}

- (void)persistToDefaultRealm:(NSDictionary*)foursquareVenues
{
   // Open the default Realm file
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];

    // Begin a write transaction to save to the default Realm
    [defaultRealm beginWriteTransaction];

    for (id venue in foursquareVenues) {
        // Store the foursquare venue name and id in a Realm Object
        Venue *newVenue = [[Venue alloc] init];
        newVenue.foursquareID = venue[@"id"];
        newVenue.name = venue[@"name"];

        // Add the Venue object to the default Realm
        // (alternatively you could serialize the API response as an NSArray and call addObjectsFromArray)
        [defaultRealm addObject:newVenue];
    }

    // Persist all the Venues with a single commit
    [defaultRealm commitWriteTransaction];

    // Show all the venues that were persisted
    NSLog(@"Here are all the venues persisted to the default Realm: \n\n %@",
          [[Venue allObjects] description]);
}

@end
