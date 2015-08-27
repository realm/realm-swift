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

#import "RLMAccessor.h"
#import "RLMOptionalBase.h"
#import "RLMObject_Private.h"
#import "RLMObjectStore.h"

@interface RLMOptionalBase ()
@property (nonatomic) id standaloneValue;
@end

@implementation RLMOptionalBase

- (instancetype)init {
    return self;
}

- (id)underlyingValue {
    if (_object && _object->_realm) {
        return RLMDynamicGet(_object, _property);
    }
    else {
        return _standaloneValue;
    }
}

- (void)setUnderlyingValue:(id)underlyingValue {
    if (_object && _object->_realm) {
        RLMDynamicSet(_object, _property, underlyingValue, RLMCreationOptionsNone);
    }
    else {
        _standaloneValue = underlyingValue;
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.underlyingValue methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    id val = self.underlyingValue;
    if (val) {
        [invocation invokeWithTarget:self.underlyingValue];
    }
}

- (id)forwardingTargetForSelector:(__unused SEL)sel {
    return self.underlyingValue;
}

@end
