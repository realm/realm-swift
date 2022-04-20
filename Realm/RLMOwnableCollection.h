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

#import <Foundation/Foundation.h>

@class RLMRealm;
@class RLMThreadSafeReference;
@protocol RLMThreadConfined;
@protocol RLMCollection;

@interface RLMOwnableCollection<__covariant Confined : id <RLMThreadConfined>> : NSObject

@property(nonatomic, strong, readonly) RLMThreadSafeReference *__nonnull threadConfined;
@property(nonatomic, strong, readonly) RLMRealm *__nonnull realm;

- (__nonnull instancetype)initWithItems:(id<RLMCollection> __nonnull)items;

- (__nonnull instancetype)initWithThreadConfined:(RLMThreadSafeReference *__nonnull)threadConfined
                                           realm:(RLMRealm *__nonnull)realm;

- (__nonnull Confined)take;

@end
