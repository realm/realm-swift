////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMSyncSessionRefreshHandle+ObjectServerTests.h"

#import "RLMTestUtils.h"

static BOOL s_calculateFireDatesWithTestLogic = NO;
static void(^s_onRefreshCompletedOrErrored)(BOOL) = nil;

@interface RLMSyncSessionRefreshHandle ()
+ (NSDate *)fireDateForTokenExpirationDate:(NSDate *)date nowDate:(NSDate *)date;
- (BOOL)_onRefreshCompletionWithError:(NSError *)error json:(NSDictionary *)json;
@end

@implementation RLMSyncSessionRefreshHandle (ObjectServerTests)

+ (void)calculateFireDateUsingTestLogic:(BOOL)forTest blockOnRefreshCompletion:(void(^)(BOOL))block {
    s_onRefreshCompletedOrErrored = block;
    s_calculateFireDatesWithTestLogic = forTest;
}

+ (void)load {
    RLMSwapOutClassMethod(self,
                          @selector(fireDateForTokenExpirationDate:nowDate:),
                          @selector(ost_fireDateForTokenExpirationDate:nowDate:));
    RLMSwapOutInstanceMethod(self,
                             @selector(_onRefreshCompletionWithError:json:),
                             @selector(ost_onRefreshCompletionWithError:json:));
}

+ (NSDate *)ost_fireDateForTokenExpirationDate:(NSDate *)date nowDate:(NSDate *)nowDate {
    if (s_calculateFireDatesWithTestLogic) {
        // Force the refresh to take place one second later.
        return [NSDate dateWithTimeIntervalSinceNow:1];
    } else {
        // Use the original logic.
        return [self ost_fireDateForTokenExpirationDate:date nowDate:nowDate];
    }
}

- (BOOL)ost_onRefreshCompletionWithError:(NSError *)error json:(NSDictionary *)json {
    BOOL status = [self ost_onRefreshCompletionWithError:error json:json];
    // For the sake of testing, call a callback afterwards to let the test update its state.
    if (s_onRefreshCompletedOrErrored) {
        s_onRefreshCompletedOrErrored(status);
    }
    return status;
}

@end
