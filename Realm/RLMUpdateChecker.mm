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
#import "RLMUtil.hpp"

#if TARGET_IPHONE_SIMULATOR && !defined(REALM_COCOA_VERSION)
#import "RLMVersion.h"
#endif

void RLMCheckForUpdates() {
#if TARGET_IPHONE_SIMULATOR
    if (getenv("REALM_DISABLE_UPDATE_CHECKER") || RLMIsRunningInPlayground()) {
        return;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"alpha|beta|rc"
                                                                           options:(NSRegularExpressionOptions)0
                                                                             error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:REALM_COCOA_VERSION
                                                        options:(NSMatchingOptions)0
                                                          range:NSMakeRange(0, REALM_COCOA_VERSION.length)];

    if (numberOfMatches > 0) {
        // pre-release version, skip update checking
        return;
    }

    auto handler = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || ((NSHTTPURLResponse *)response).statusCode != 200) {
            return;
        }

        NSString *latestVersion = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![REALM_COCOA_VERSION isEqualToString:latestVersion]) {
            NSLog(@"Version %@ of Realm is now available: https://github.com/realm/realm-cocoa/blob/v%@/CHANGELOG.md", latestVersion, latestVersion);
        }
    };

    NSString *url = [NSString stringWithFormat:@"https://static.realm.io/update/cocoa?%@", REALM_COCOA_VERSION];
    [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:handler] resume];
#endif
}
