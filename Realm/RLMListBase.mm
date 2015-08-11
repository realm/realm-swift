////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMListBase.h"

#import "RLMArray_Private.hpp"
#import "RLMObservation.hpp"

@interface RLMArray (KVO)
- (NSArray *)objectsAtIndexes:(__unused NSIndexSet *)indexes;
@end

@implementation RLMListBase {
    std::unique_ptr<RLMObservationInfo> _observationInfo;
}

- (instancetype)initWithArray:(RLMArray *)array {
    self = [super init];
    if (self) {
        __rlmArray = array;
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    return [__rlmArray valueForKey:key];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
    return [__rlmArray countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
    return [__rlmArray objectsAtIndexes:indexes];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    RLMEnsureArrayObservationInfo(_observationInfo, keyPath, __rlmArray, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

@end
