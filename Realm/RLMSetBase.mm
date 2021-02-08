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

#import "RLMSetBase.h"

#import "RLMObjectSchema_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMSet_Private.hpp"

@implementation RLMSetBase {
    std::unique_ptr<RLMObservationInfo> _observationInfo;
}

+ (RLMSet *)_unmanagedSet {
    return nil;
}

- (instancetype)init {
    return self = [super init];
}

- (instancetype)initWithSet:(RLMSet *)set {
    self = [super init];
    if (self) {
        __rlmCollection = set;
    }
    return self;
}

- (RLMSet *)_rlmCollection {
    if (!__rlmCollection) {
        __rlmCollection = self.class._unmanagedSet;
    }
    return __rlmCollection;
}

- (id)valueForKey:(NSString *)key {
    return [self._rlmCollection valueForKey:key];
}

- (id)valueForKeyPath:(NSString *)keyPath {
    return [self._rlmCollection valueForKeyPath:keyPath];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    return [self._rlmCollection countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self._rlmCollection objectAtIndex:index];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    RLMEnsureSetObservationInfo(_observationInfo, keyPath, self._rlmCollection, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (BOOL)isEqual:(id)object {
    if (auto set = RLMDynamicCast<RLMSetBase>(object)) {
        return !set._rlmCollection.realm
        && ((self._rlmCollection.count == 0 && set._rlmCollection.count == 0) ||
            [self._rlmCollection isEqual:set._rlmCollection]);
    }
    return NO;
}

@end
