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

@implementation RLMDictionary

- (BOOL)isInvalidated {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (NSUInteger)count {
    return 0;
}

- (nonnull RLMNotificationToken *)addNotificationBlock:(nonnull void (^)(id<RLMCollection> _Nullable, RLMCollectionChange * _Nullable, NSError * _Nullable))block {
    @throw RLMException(@"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (nullable NSNumber *)averageOfProperty:(nonnull NSString *)property {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (instancetype)freeze {
    @throw RLMException(@"This method may only be called on RLMDictionary instances retrieved from an RLMRealm");
}

- (nullable id)maxOfProperty:(nonnull NSString *)property {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nullable id)minOfProperty:(nonnull NSString *)property {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull id)objectAtIndex:(NSUInteger)index {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)objectsWhere:(nonnull NSString *)predicateFormat, ... {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)objectsWhere:(nonnull NSString *)predicateFormat args:(va_list)args {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)objectsWithPredicate:(nonnull NSPredicate *)predicate {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (void)setValue:(nullable id)value forKey:(nonnull NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)sortedResultsUsingDescriptors:(nonnull NSArray<RLMSortDescriptor *> *)properties {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull RLMResults *)sortedResultsUsingKeyPath:(nonnull NSString *)keyPath ascending:(BOOL)ascending {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nonnull NSNumber *)sumOfProperty:(nonnull NSString *)property {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

- (nullable id)valueForKey:(nonnull NSString *)key {
    @throw RLMException(@"Not implemented in RLMDictionary");
}

@end
