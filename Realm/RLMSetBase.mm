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

#import "RLMSet_Private.hpp"
#import "RLMObjectSchema_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"

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
        __rlmSet = set;
    }
    return self;
}

- (RLMSet *)_rlmSet {
    if (!__rlmSet) {
        __rlmSet = self.class._unmanagedSet;
    }
    return __rlmSet;
}

- (id)valueForKey:(NSString *)key {
    return [self._rlmSet valueForKey:key];
}

- (id)valueForKeyPath:(NSString *)keyPath {
    return [self._rlmSet valueForKeyPath:keyPath];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    return [self._rlmSet countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self._rlmSet objectAtIndex:index];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    RLMEnsureSetObservationInfo(_observationInfo, keyPath, self._rlmSet, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (BOOL)isEqual:(id)object {
    if (auto set = RLMDynamicCast<RLMSetBase>(object)) {
        return !set._rlmSet.realm
        && ((self._rlmSet.count == 0 && set._rlmSet.count == 0) ||
            [self._rlmSet isEqual:set._rlmSet]);
    }
    return NO;
}

@end
