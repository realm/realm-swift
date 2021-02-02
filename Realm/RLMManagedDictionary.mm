////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#include "RLMDictionary.h"
#include "RLMUtil.hpp"

@interface RLMManagedDictionary: RLMDictionary
@end

@implementation RLMManagedDictionary

- (nonnull RLMNotificationToken *)addNotificationBlock:(nonnull void (^)(id<RLMCollection> _Nullable, RLMCollectionChange * _Nullable, NSError * _Nullable))block {
    @throw RLMException(@"Not implemented in RLMManagedDictionary");
}

- (instancetype)freeze {
    @throw RLMException(@"Not implemented in RLMManagedDictionary");
}

- (nonnull RLMResults *)objectsWithPredicate:(nonnull NSPredicate *)predicate {
    @throw RLMException(@"Not implemented in RLMManagedDictionary");
}

- (nonnull RLMResults *)sortedResultsUsingDescriptors:(nonnull NSArray<RLMSortDescriptor *> *)properties {
    @throw RLMException(@"Not implemented in RLMManagedDictionary");
}

@end
