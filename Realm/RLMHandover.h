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

/// A Realm-bound object that can only be passed between threads by exporting for handover
@protocol RLMThreadConfined <NSObject>

/// The `RLMRealm` the object is associated with
@property (nonatomic, readonly, nullable) RLMRealm *realm;

// Runtime-enforced requirement that type also conforms to `RLMThreadConfined_Private`

@end

/// An object containing the data imported from handover
@interface RLMThreadImport : NSObject

/// The `RLMRealm` from which the `objects` were handed over
@property (nonatomic, readonly) RLMRealm *realm;

/// Objects equivalent to those handed over but associated with this thread's `realm`
@property (nonatomic, readonly) NSArray<id<RLMThreadConfined>> *objects;

@end

/// An object intended to be passed between threads containing information about objects being handed over
@interface RLMThreadHandover : NSObject

/**
 Imports the handover package, creating an instance of the realm and objects on the current thread.

 This method may be not be called more than once on a given handover package. The realm version will
 remain pinned until this method is called or the object is deinitialized.

 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.
              If you are not interested in possible errors, pass in `NULL`.
 
 @return A `RLMThreadImport` instance with the imported `objects` and their associated `realm`.

 @see RLMThreadHandover
 */
- (nullable RLMThreadImport *)importOnCurrentThreadWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
