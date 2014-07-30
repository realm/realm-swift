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

#warning Provide your foursquare client ID and client secret
NSString *clientID = @"B24JYU5DQ2ZYV2IQ4C51IAPDOSYH4GZTFCQO4MGUG12FUPIQ";
NSString *clientSecret = @"0FHSVHUYZHIYB3SDHR5Y0IBMFGJQIMNSFIX0LPPXSDWIUCT2";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    UIViewController *rootVC = [[UIViewController alloc] init];
    [self.window setRootViewController:rootVC];
    
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
    
    [defaultRealm beginWriteTransaction];
    
    for (id venue in foursquareVenues) {
        // Check if a Venue with the same ID already exists in the deafult Realm
        RLMArray *existingVenue = [defaultRealm objects:[Venue className]
                                          withPredicate:[NSPredicate predicateWithFormat:@"foursquareID==%@",venue[@"id"]]];
        if ([existingVenue count] == 0) {
            // Create the new Venue
            Venue *newVenue = [[Venue alloc] init];
            newVenue.name = venue[@"name"];
            newVenue.foursquareID = venue[@"id"];
            [defaultRealm addObject:newVenue];
        } else if (![existingVenue[0][@"name"] isEqualToString:venue[@"name"]]) {
            // Update the existing Venue properties
            existingVenue[0][@"name"] = venue[@"name"];
        }
    }
    
    [defaultRealm commitWriteTransaction];
    
    // Show all the venues that were persisted
    NSLog(@"Here are all the venues that have been persisted to the default Realm: \n\n %@",
          [[Venue allObjects] description]);
}

@end
