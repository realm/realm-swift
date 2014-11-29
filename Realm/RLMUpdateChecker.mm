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
#include <sys/sysctl.h>

#import "RLMRealm.h"

#if defined(DEBUG) && !defined(REALM_VERSION)
#import "RLMVersion.h"

static inline bool isDebuggerAttached() {
    int name[] = {
        CTL_KERN,
        KERN_PROC,
        KERN_PROC_PID,
        getpid()
    };

    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    if (sysctl(name, sizeof(name)/sizeof(name[0]), &info, &info_size, NULL, 0) == -1) {
        return false;
    }

    return (info.kp_proc.p_flag & P_TRACED) != 0;
}
#endif

void RLMCheckForUpdates() {
#if defined(DEBUG) && defined(REALM_VERSION)
    if (isDebuggerAttached()) {
        if (getenv("REALM_DISABLE_UPDATE_CHECKER") || ![NSUserDefaults instancesRespondToSelector:@selector(initWithSuiteName:)]) {
            return;
        }

        auto handler = ^(NSData *data, __unused NSURLResponse *response, NSError *error) {
            if (error) {
                return;
            }

            NSString *latestVersion = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (![REALM_VERSION isEqualToString:latestVersion]) {
                NSLog(@"Version %@ of Realm is now available: http://static.realm.io/downloads/cocoa/latest", latestVersion);
            }
        };

        NSString *url = [NSString stringWithFormat:@"http://static.realm.io/update/cocoa?%@", REALM_VERSION];
        [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:handler] resume];
    }
#endif
}
