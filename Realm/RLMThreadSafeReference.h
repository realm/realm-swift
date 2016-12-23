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

#import <Foundation/Foundation.h>

@class RLMRealm;

NS_ASSUME_NONNULL_BEGIN

@protocol RLMThreadConfined <NSObject>
// Must also conform to `RLMThreadConfined_Private`

/**
 The Realm which manages the instance. Returns `nil` for unmanaged instances.
 */
@property (nonatomic, readonly, nullable) RLMRealm *realm;

/**
 Indicates if the object can no longer be accessed.
 */
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

@end

@interface RLMThreadSafeReference<__covariant Confined : id<RLMThreadConfined>> : NSObject

// TODO: Document
+ (instancetype)referenceWithThreadConfined:(Confined)threadConfined;

/**
 Indicates if the reference can no longer be resolved.
 */
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

@end

NS_ASSUME_NONNULL_END
