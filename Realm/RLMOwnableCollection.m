////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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
#import "RLMRealm.h"
#import "RLMThreadSafeReference.h"
#import "RLMCollection.h"
#import "RLMOwnableCollection.h"
#import "RLMThreadSafeReference.h"


@implementation RLMOwnableCollection

- (instancetype)initWithItems:(id<RLMCollection>)items {
    if (items.realm != nil) {
        id reference = [RLMThreadSafeReference referenceWithThreadConfined:items];
        return [self initWithThreadConfined:reference realm:items.realm];
    } else {
        [NSException raise:NSInternalInconsistencyException format:@"Item realm can't be nil"];
        return nil;
    }
}

- (instancetype)initWithThreadConfined:(RLMThreadSafeReference *)threadConfined realm:(RLMRealm *)realm {
    self = [super init];
    if (self) {
        _threadConfined = threadConfined;
        _realm = realm;
    }
    return self;
}

- (id)take {
    id result = [_realm resolveThreadSafeReference:_threadConfined];
    if (result) {
        return result;
    } else {
        [NSException raise:NSInternalInconsistencyException format:@"Object was deleted in another thread"];
        return nil;
    }
}


@end
