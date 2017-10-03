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

#import "RLMRealm+Sync.h"

#import "RLMObjectBase.h"
#import "RLMObjectSchema.h"
#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.hpp"
#import "RLMSchema.h"

#import "results.hpp"
#import "sync/partial_sync.hpp"
#import "shared_realm.hpp"

using namespace realm;

@implementation RLMRealm (Sync)

- (void)subscribeToObjects:(Class)type where:(NSString *)query callback:(RLMPartialSyncFetchCallback)callback {
    NSString *className = [type className];
    auto cb = [=](Results results, std::exception_ptr err) {
        if (err) {
            try {
                rethrow_exception(err);
            }
            catch (...) {
                NSError *error = nil;
                RLMRealmTranslateException(&error);
                callback(nil, error);
            }
            return;
        }
        callback([RLMResults resultsWithObjectInfo:_info[className] results:std::move(results)], nil);
    };
    partial_sync::register_query(_realm, className.UTF8String, query.UTF8String, std::move(cb));
}

@end
