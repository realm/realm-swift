////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#import "RLMDictionaryBase.h"
#import "RLMDictionary.h"
#import "RLMUtil.hpp"

@implementation RLMDictionaryBase

- (instancetype)init {
    return self = [super init];
}

- (instancetype)initWithDictionary:(RLMDictionary *)dictionary {
    self = [super init];
    if (self) {
        __rlmDictionary = dictionary;
    }
    return self;
}

- (RLMDictionary *)_rlmDictionary {
    if (!__rlmDictionary) {
        __rlmDictionary = self.class._unmanagedDictionary;
    }
    return __rlmDictionary;
}

+ (RLMDictionary *)_unmanagedDictionary {
    return nil;
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nullable * _Nonnull)buffer count:(NSUInteger)len {
    @throw RLMException(@"Not implemented in RLMDictionaryBase");
}

- (id)objectForKey:(NSString *)key {
    return [self._rlmDictionary objectForKey:key];
}

@end
