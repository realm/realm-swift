//
//  RLMHandoverable.h
//  Realm
//
//  Created by Realm on 7/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLMRealm;

/// An Realm-bound object that can be handed over between threads
@protocol RLMHandoverable <NSObject>

/// The `RLMRealm` the object is associated with
@property (nonatomic, readonly, nullable) RLMRealm *realm;

// Runtime-enforced requirement that type also conforms to `RLMHandoverable_Private`

@end

NS_ASSUME_NONNULL_END
