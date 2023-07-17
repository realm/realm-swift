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

#import "RLMClassInfo.hpp"

#import <memory>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

namespace realm {
    class Group;
    class Realm;
}

@interface RLMRealm () {
    @public
    std::shared_ptr<realm::Realm> _realm;
    RLMSchemaInfo _info;
}

+ (instancetype)realmWithSharedRealm:(std::shared_ptr<realm::Realm>)sharedRealm
                              schema:(nullable RLMSchema *)schema
                             dynamic:(bool)dynamic
    freeze:(bool)freeze NS_RETURNS_RETAINED;

@property (nonatomic, readonly) realm::Group &group;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
