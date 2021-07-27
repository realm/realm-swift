////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import <Realm/RLMSet.h>
#import <Realm/RLMConstants.h>

@class RLMObjectBase, RLMProperty;

NS_ASSUME_NONNULL_BEGIN

@interface RLMSet ()
- (instancetype)initWithObjectClassName:(NSString *)objectClassName;
- (instancetype)initWithObjectType:(RLMPropertyType)type optional:(BOOL)optional;
- (NSString *)descriptionWithMaxDepth:(NSUInteger)depth;
- (void)setParent:(RLMObjectBase *)parentObject property:(RLMProperty *)property;
// YES if the property is declared with old property syntax.
@property (nonatomic, readonly) BOOL isLegacyProperty;
// The name of the property which this collection represents
@property (nonatomic, readonly) NSString *propertyKey;
@end

void RLMSetValidateMatchingObjectType(RLMSet *set, id value);

@interface RLMManagedSet : RLMSet
- (instancetype)initWithParent:(RLMObjectBase *)parentObject property:(RLMProperty *)property;
@end

NS_ASSUME_NONNULL_END
