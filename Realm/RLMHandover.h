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

/**
 An object which is bound to a thread-specific RLMRealm instance, and so cannot be passed between
 threads without being explicitly exported and imported.

 Objects of classes conforming to this protocol can be packaged for transport between threads by calling
 `-[RLMRealm exportThreadHandoverWithObjects:]`. Note that only types defined by Realm can meaningfully conform
 to this protocol, and defining new classes which attempt to conform to it will not make them work with
 `-exportThreadHandoverWithObjects:`.
 */
@protocol RLMThreadConfined <NSObject>

/// The Realm which manages the object, or `nil` if the object is unmanaged.
@property (nonatomic, readonly, nullable) RLMRealm *realm;

// Conformance to the `RLMThreadConfined_Private` protocol will be enforced at runtime.
@end

/// An object containing the data to be imported from handover.
@interface RLMThreadImport : NSObject

/// The destination `RLMRealm` that the object was imported into.
@property (nonatomic, readonly) RLMRealm *realm;

/// Objects equivalent to those handed over but associated with this thread's Realm.
@property (nonatomic, readonly) NSArray<id<RLMThreadConfined>> *objects;

@end

/// An object intended to be passed between threads containing information about which objects are
/// being handed over.
@interface RLMThreadHandover : NSObject

/**
 Imports the handover package, creating an instance of the `RLMRealm` and the contained objects on
 the current thread.

 This method may be not be called more than once on a given handover package. The `RLMRealm` version
 will remain _pinned_ until this method is called or this instance is deinitialized.

 @param error If an error occurs, this `NSError` object will be populated with information about the problem.
              If you are not interested in possible errors, pass in `NULL`. In the case of an error, the
              handover is invalidated and cannot be imported again.

 @return An `RLMThreadImport` instance with the imported `objects` and their associated `RLMRealm`.

 @see RLMThreadImport
 */
- (nullable RLMThreadImport *)importOnCurrentThreadWithError:(NSError **)error;

#pragma mark - Unavailable Methods

/**
 `-[RLMThreadHandover init]` is not available because `RLMThreadHandover` cannot be created directly.
 `RLMThreadHandover` instances must be obtained by calling `-[RLMRealm exportThreadHandoverWithObjects:]`.
 */
- (instancetype)init __attribute__((unavailable("RLMThreadHandover cannot be created directly")));

/**
 `+[RLMThreadHandover new]` is not available because `RLMThreadHandover` cannot be created directly.
 `RLMThreadHandover` instances must be obtained by calling `-[RLMRealm exportThreadHandoverWithObjects:]`.
 */
+ (instancetype)new __attribute__((unavailable("RLMThreadHandover cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
