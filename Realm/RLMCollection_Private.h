////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import <Realm/RLMCollection.h>

#import <Realm/RLMRealm.h>

@protocol RLMFastEnumerable;

NS_ASSUME_NONNULL_BEGIN

void RLMCollectionSetValueForKey(id<RLMFastEnumerable> collection, NSString *key, id _Nullable value);
FOUNDATION_EXTERN NSString *RLMDescriptionWithMaxDepth(NSString *name, id<RLMCollection> collection, NSUInteger depth);
FOUNDATION_EXTERN void RLMAssignToCollection(id<RLMCollection> collection, id value);
FOUNDATION_EXTERN id _Nullable (*_Nullable RLMSwiftBridgeValue)(id);

typedef RLM_CLOSED_ENUM(int32_t, RLMCollectionType) {
    RLMCollectionTypeArray = 0,
    RLMCollectionTypeSet = 1,
    RLMCollectionTypeDictionary = 2
};

NS_ASSUME_NONNULL_END
