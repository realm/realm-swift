////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import "RLMClassInfo.hpp"
#import "RLMSectionedResults.h"

#import <realm/object-store/results.hpp>
#import <realm/object-store/sectioned_results.hpp>

@protocol RLMValue;

NS_ASSUME_NONNULL_BEGIN

typedef id<RLMValue>_Nullable(^RLMSectionedResultsKeyBlock)(id);

@interface RLMSectionedResultsChange ()
- (instancetype)initWithChanges:(realm::SectionedResultsChangeSet)indices;
@end

@interface RLMSectionedResultsEnumerator : NSObject

@property (nonatomic, readonly) RLMSectionedResults *sectionedResults;
@property (nonatomic, readonly) RLMSection *resultsSection;

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len;

- (instancetype)initWithSectionedResults:(RLMSectionedResults *)sectionedResults;
- (instancetype)initWithResultsSection:(RLMSection *)resultsSection;

@end

@interface RLMSectionedResults () {
    @public
    realm::SectionedResults _sectionedResults;
    RLMSectionedResultsKeyBlock _keyBlock;
    // We need to hold a reference to the parent
    // Results so we can obtain a ThreadSafeReference
    // for notifications.
    realm::Results _results;
}

- (instancetype)initWithResults:(RLMResults *)results
                     objectInfo:(RLMClassInfo&)objectInfo
                       keyBlock:(RLMSectionedResultsKeyBlock)keyBlock;

- (instancetype)initWithResults:(realm::Results&&)results
                          realm:(RLMRealm *)realm
                     objectInfo:(RLMClassInfo&)objectInfo
                       keyBlock:(RLMSectionedResultsKeyBlock)keyBlock;

- (RLMRealm *)realm;

- (RLMSectionedResultsEnumerator *)fastEnumerator;
- (RLMClassInfo *)objectInfo;
- (RLMSectionedResults *)snapshot;

NSUInteger RLMFastEnumerate(NSFastEnumerationState *state,
                            NSUInteger len,
                            RLMSectionedResults *collection);

@end

@interface RLMSection () {
    @public
    realm::ResultsSection _resultsSection;
}

- (instancetype)initWithResultsSection:(realm::ResultsSection&&)resultsSection
                                 realm:(RLMRealm *)realm
                            objectInfo:(RLMClassInfo&)objectInfo
                              keyBlock:(RLMSectionedResultsKeyBlock)keyBlock;


- (RLMSectionedResultsEnumerator *)fastEnumerator;
- (RLMClassInfo *)objectInfo;

NSUInteger RLMFastEnumerate(NSFastEnumerationState *state,
                            NSUInteger len,
                            RLMSection *collection);

@end

NS_ASSUME_NONNULL_END
