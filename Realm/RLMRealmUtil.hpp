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

#import <Realm/RLMConstants.h>

#import <memory>
#import <string>

@class RLMRealm, RLMRealmConfiguration, RLMScheduler;

namespace realm {
    class BindingContext;
}

// Add a Realm to the weak cache
void RLMCacheRealm(RLMRealmConfiguration *configuration,
                   RLMScheduler *options,
                   RLMRealm *realm);
RLMRealm *RLMGetAnyCachedRealmForPath(std::string const& path) NS_RETURNS_RETAINED;
// Clear the weak cache of Realms
void RLMClearRealmCache();

RLMRealm *RLMGetFrozenRealmForSourceRealm(RLMRealm *realm) NS_RETURNS_RETAINED;

std::unique_ptr<realm::BindingContext> RLMCreateBindingContext(RLMRealm *realm);
