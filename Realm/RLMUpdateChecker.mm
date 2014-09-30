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

#import "RLMUpdateChecker.hpp"

#import "RLMRealm.h"

#if TARGET_IPHONE_SIMULATOR && !defined(REALM_VERSION)
#import "RLMVersion.h"
#endif

void RLMCheckForUpdates() {
#if TARGET_IPHONE_SIMULATOR
    if (getenv("REALM_DISABLE_UPDATE_CHECKER") || ![NSUserDefaults instancesRespondToSelector:@selector(initWithSuiteName:)]) {
        return;
    }

    // Only check if it's been at least a day since our last check
    NSUserDefaults *settings = [[NSUserDefaults alloc] initWithSuiteName:@"io.Realm.Realm"];
    double lastUpdateCheck = [settings doubleForKey:@"Last Update Check"];
    if (NSDate.timeIntervalSinceReferenceDate - lastUpdateCheck < 24 * 60 * 60) {
        return;
    }

    auto handler = ^(NSData *data, __unused NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Failed to check for updates to Realm: %@", error);
            return;
        }

        NSString *latestVersion = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![REALM_VERSION isEqualToString:latestVersion]) {
            NSLog(@"Version %@ of Realm is now available: http://static.realm.io/downloads/cocoa/latest", latestVersion);
        }

        [settings setDouble:NSDate.timeIntervalSinceReferenceDate forKey:@"Last Update Check"];
    };

    NSString *url = [NSString stringWithFormat:@"http://static.realm.io/update/cocoa?%@", REALM_VERSION];
    [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:handler] resume];
#endif
}
