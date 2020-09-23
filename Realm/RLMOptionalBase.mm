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

#import "RLMOptionalBase.h"

#import "RLMAccessor.hpp"
#import "RLMObject_Private.hpp"
#import "RLMProperty.h"
#import "RLMUtil.hpp"

#import <realm/object-store/object.hpp>

namespace {
struct OptionalBase {
    virtual id get() = 0;
    virtual void set(id) = 0;
    virtual ~OptionalBase() = default;
};

class UnmanagedOptional : public OptionalBase {
public:
    id get() override {
        return _value;
    }

    void set(__unsafe_unretained const id newValue) override {
        @autoreleasepool {
            RLMObjectBase *object = _parent;
            [object willChangeValueForKey:_property];
            _value = newValue;
            [object didChangeValueForKey:_property];
        }
    }

    void attach(__unsafe_unretained RLMObjectBase *const obj, NSString *property) {
        if (!_property) {
            _property = property;
            _parent = obj;
        }
    }

private:
    id _value;
    NSString *_property;
    __weak RLMObjectBase *_parent;

};

class ManagedOptional : public OptionalBase {
public:
    ManagedOptional(RLMObjectBase *obj, RLMProperty *prop)
    : _realm(obj->_realm)
    , _object(obj->_realm->_realm, *obj->_info->objectSchema, obj->_row)
    , _propertyName(prop.name.UTF8String)
    , _ctx(*obj->_info)
    {
    }

    id get() override {
        return _object.get_property_value<id>(_ctx, _propertyName);
    }

    void set(__unsafe_unretained id const value) override {
        _object.set_property_value(_ctx, _propertyName, value ?: NSNull.null);
    }

private:
    // We have to hold onto a strong reference to the Realm as
    // RLMAccessorContext holds a non-retaining one.
    __unused RLMRealm *_realm;
    realm::Object _object;
    std::string _propertyName;
    RLMAccessorContext _ctx;
};
} // anonymous namespace

@interface RLMOptionalBase () {
    std::unique_ptr<OptionalBase> _impl;
}
@end

@implementation RLMOptionalBase
- (instancetype)init {
    return self;
}

- (BOOL)isKindOfClass:(Class)aClass {
    return [RLMGetOptional(self) isKindOfClass:aClass] || RLMIsKindOfClass(object_getClass(self), aClass);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [RLMGetOptional(self) methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:RLMGetOptional(self)];
}

- (id)forwardingTargetForSelector:(__unused SEL)sel {
    return RLMGetOptional(self);
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [RLMGetOptional(self) respondsToSelector:aSelector];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector {
    [RLMGetOptional(self) doesNotRecognizeSelector:aSelector];
}

id RLMGetOptional(__unsafe_unretained RLMOptionalBase *const self) {
    try {
        return self->_impl ? RLMCoerceToNil(self->_impl->get()) : nil;
    }
    catch (std::exception const& err) {
        @throw RLMException(err);
    }
}

void RLMSetOptional(__unsafe_unretained RLMOptionalBase *const self, __unsafe_unretained const id value) {
    try {
        if (!self->_impl && value) {
            self->_impl.reset(new UnmanagedOptional);
        }
        if (self->_impl) {
            self->_impl->set(value);
        }
    }
    catch (std::exception const& err) {
        @throw RLMException(err);
    }
}

void RLMInitializeManagedOptional(__unsafe_unretained RLMOptionalBase *const self,
                                  __unsafe_unretained RLMObjectBase *const parent,
                                  __unsafe_unretained RLMProperty *const prop) {
    REALM_ASSERT(parent->_realm);
    self->_impl.reset(new ManagedOptional(parent, prop));
}

void RLMInitializeUnmanagedOptional(__unsafe_unretained RLMOptionalBase *const self,
                                    __unsafe_unretained RLMObjectBase *const parent,
                                    __unsafe_unretained RLMProperty *const prop) {
    if (!self->_impl) {
        self->_impl.reset(new UnmanagedOptional);
    }
    static_cast<UnmanagedOptional&>(*self->_impl).attach(parent, prop.name);
}
@end
