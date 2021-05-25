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

#import <Realm/RLMDictionary.h>

@class RLMObjectBase, RLMProperty;

NS_ASSUME_NONNULL_BEGIN

@interface RLMDictionary ()
- (instancetype)initWithObjectClassName:(NSString *)objectClassName keyType:(RLMPropertyType)keyType;
- (instancetype)initWithObjectType:(RLMPropertyType)type optional:(BOOL)optional keyType:(RLMPropertyType)keyType;
- (NSString *)descriptionWithMaxDepth:(NSUInteger)depth;
- (void)setParent:(RLMObjectBase *)parentObject property:(RLMProperty *)property;
@end

@interface RLMManagedDictionary : RLMDictionary
- (instancetype)initWithParent:(RLMObjectBase *)parentObject property:(RLMProperty *)property;
@end

void RLMDictionaryValidateMatchingObjectType(__unsafe_unretained RLMDictionary *const dictionary,
                                             __unsafe_unretained id const key, __unsafe_unretained id const value);
FOUNDATION_EXTERN NSString *RLMDictionaryDescriptionWithMaxDepth(NSString *name,
                                                                 RLMDictionary *dictionary,
                                                                 NSUInteger depth);
NS_ASSUME_NONNULL_END
