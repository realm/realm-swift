//
//  RLMHandover.h
//  Realm
//
//  Created by Realm on 7/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLMRealm;

NS_ASSUME_NONNULL_BEGIN

/// An Realm-bound object that can be handed over between threads
@protocol RLMHandoverable <NSObject>

/// The `RLMRealm` the object is associated with
@property (nonatomic, readonly, nullable) RLMRealm *realm;

// Runtime-enforced requirement that type also conforms to `RLMHandoverable_Private`

@end

@interface RLMHandoverImport : NSObject

/// The `RLMRealm` from which the `objects` were handed over
@property (nonatomic, readonly) RLMRealm *realm;

/// Objects equivalent to those handed over but associated with this thread's `realm`
@property (nonatomic, readonly) NSArray<id<RLMHandoverable>> *objects;

@end

@interface RLMHandoverPackage : NSObject

/**
 Imports the handover package, creating an instance of the realm and objects on the current thread.

 This method may be not be called more than once on a given handover package. The realm version will
 remain pinned until this method is called or the object is deinitialized.

 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
              If you are not interested in possible errors, pass in `NULL`.
 
 @return A `RLMHandoverImport` instance with the imported `objects` and their associated `realm`.

 @see RLMHandoverPackage
 */
- (nullable RLMHandoverImport *)importOnCurrentThreadWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
