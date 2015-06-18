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

#import "RLMRealm_Private.h"
#import "RLMUtil.hpp"

#import <realm/link_view.hpp>
#import <realm/group.hpp>
#import <pthread.h>

namespace realm {
    class Group;
}

@interface RLMRealm ()
// FIXME - group should not be exposed
@property (nonatomic, readonly) realm::Group *group;
- (void)verifyThread;
- (void)notify;
- (void)cacheTableAccessors;
@end
