//
//  RLMThreadSafeReference.h
//  Realm
//
//  Created by Realm on 9/7/16.
//  Copyright © 2016 Realm. All rights reserved.
//

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
