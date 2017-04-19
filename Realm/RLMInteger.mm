////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMInteger_Private.hpp"

#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty.h"
#import "RLMRealm_Private.h"
#import "RLMUtil.hpp"

template<typename T> static inline void verifyAttached(__unsafe_unretained T const obj) {
    if (!obj->_row.is_attached()) {
        @throw RLMException(@"Integer has been deleted or invalidated.");
    }
    [obj->_realm verifyThread];
}

template<typename T> static inline void verifyInWriteTransaction(__unsafe_unretained T const obj) {
    verifyAttached(obj);
    if (!obj->_realm.inWriteTransaction) {
        @throw RLMException(@"Attempting to modify integer outside of a write transaction - call beginWriteTransaction on an RLMRealm instance first.");
    }
}

namespace {
    
void set_nullable_int(NSNumber<RLMInt> *value, realm::Row& row, size_t colIndex, size_t rowIndex) {
    if (value) {
        row.get_table()->set_int(colIndex, rowIndex, value.longLongValue, false);
    } else {
        row.get_table()->set_null(colIndex, rowIndex);
    }
}
    
template <typename TableType>
void increment_nullable_int(TableType table, size_t colIndex, size_t rowIndex, NSInteger delta) {
    if (table->is_null(colIndex, rowIndex)) {
        @throw RLMException(@"Cannot increment a RLMNullableInteger property whose value is nil. Set its value first.");
    }
    table->add_int(colIndex, rowIndex, delta);
}
    
}

@implementation RLMInteger

- (instancetype)init {
    if (self = [super init]) {
        _value = 0;
    }
    return self;
}

- (instancetype)initWithValue:(NSInteger)value {
    if (self = [super init]) {
        _value = value;
    }
    return self;
}

- (void)setValue:(NSInteger)value {
    realm::Row row;
    if (_object) {
        REALM_ASSERT_DEBUG(_name);
        if (RLMObservationInfo *info = RLMGetObservationInfo(_object->_observationInfo, row.get_index(), *_object->_info)) {
            info->willChange(_name);
            _value = value;
            info->didChange(_name);
            return;
        }
    }
    _value = value;
}

- (void)incrementValueBy:(NSInteger)delta {
    self.value += delta;
}

- (NSNumber<RLMInt> *)boxedValue {
    return @(self.value);
}

- (BOOL)isEqual:(id)object {
    if ([object conformsToProtocol:@protocol(RLMIntegerProtocol)]) {
        NSNumber<RLMInt> *thatValue = [object boxedValue];
        return (thatValue != nil) && [object boxedValue].integerValue == self.value;
    }
    return NO;
}

@end

@implementation RLMNullableInteger

- (instancetype)init {
    if (self = [super init]) {
        _value = nil;
    }
    return self;
}

- (instancetype)initWithValue:(NSNumber<RLMInt> *)value {
    if (self = [super init]) {
        _value = value;
    }
    return self;
}

- (void)setValue:(NSNumber<RLMInt> *)value {
    realm::Row row;
    if (_object) {
        REALM_ASSERT_DEBUG(_name);
        if (RLMObservationInfo *info = RLMGetObservationInfo(_object->_observationInfo, row.get_index(), *_object->_info)) {
            info->willChange(_name);
            _value = value;
            info->didChange(_name);
            return;
        }
    }
    _value = value;
}

- (void)incrementValueBy:(NSInteger)delta {
    if (!_value) {
        @throw RLMException(@"Cannot increment a RLMNullableInteger property whose value is nil. Set its value first.");
    }
    self.value = @(_value.integerValue + delta);
}

- (NSNumber<RLMInt> *)boxedValue {
    return self.value;
}

- (BOOL)isEqual:(id)object {
    NSNumber<RLMInt> *value = self.value;
    if ([object conformsToProtocol:@protocol(RLMIntegerProtocol)]) {
        NSNumber<RLMInt> *thatValue = [object boxedValue];
        return (!value && !thatValue) || [value isEqual:thatValue];
    }
    return NO;
}

@end

@interface RLMIntegerView () {
    @public
    RLMRealm *_realm;
    realm::Row _row;
    size_t _colIndex;
}
@end

@implementation RLMIntegerView

- (instancetype)initWithValue:(__unused NSInteger)value {
    @throw RLMException(@"Cannot initialize a RLMIntegerView using initWithValue:");
    return nil;
}

- (instancetype)initWithRow:(realm::Row)row columnIndex:(size_t)colIndex object:(RLMObjectBase *)object name:(NSString *)name realm:(RLMRealm *)realm {
    if (self = [super init]) {
        _name = name;
        _object = object;
        _row = row;
        _colIndex = colIndex;
        _realm = realm;
    }
    return self;
}

- (void)setValue:(NSInteger)value {
    verifyInWriteTransaction(self);
    size_t rowIndex = _row.get_index();
    if (RLMObservationInfo *info = RLMGetObservationInfo(_object->_observationInfo, rowIndex, *_object->_info)) {
        info->willChange(_name);
        _row.get_table()->set_int(_colIndex, rowIndex, value, false);
        info->didChange(_name);
    } else {
        _row.get_table()->set_int(_colIndex, rowIndex, value, false);
    }
}

- (NSInteger)value {
    verifyAttached(self);
    return _row.get_table()->get_int(_colIndex, _row.get_index());
}

- (void)incrementValueBy:(NSInteger)delta {
    verifyInWriteTransaction(self);
    size_t rowIndex = _row.get_index();
    if (RLMObservationInfo *info = RLMGetObservationInfo(_object->_observationInfo, rowIndex, *_object->_info)) {
        info->willChange(_name);
        _row.get_table()->add_int(_colIndex, rowIndex, delta);
        info->didChange(_name);
    } else {
        _row.get_table()->add_int(_colIndex, rowIndex, delta);
    }
}

@end

@interface RLMNullableIntegerView () {
    @public
    RLMRealm *_realm;
    realm::Row _row;
    size_t _colIndex;
}
@end

@implementation RLMNullableIntegerView

- (instancetype)initWithValue:(__unused NSNumber<RLMInt> *)value {
    @throw RLMException(@"Cannot initialize a RLMNullableIntegerView using initWithValue:");
    return nil;
}

- (instancetype)initWithRow:(realm::Row)row columnIndex:(size_t)colIndex object:(RLMObjectBase *)object name:(NSString *)name realm:(RLMRealm *)realm {
    if (self = [super init]) {
        _name = name;
        _object = object;
        _row = row;
        _colIndex = colIndex;
        _realm = realm;
    }
    return self;
}

- (void)setValue:(NSNumber<RLMInt> *)value {
    verifyInWriteTransaction(self);
    size_t rowIndex = _row.get_index();
    if (RLMObservationInfo *info = RLMGetObservationInfo(_object->_observationInfo, rowIndex, *_object->_info)) {
        info->willChange(_name);
        set_nullable_int(value, _row, _colIndex, rowIndex);
        info->didChange(_name);
    } else {
        set_nullable_int(value, _row, _colIndex, rowIndex);
    }
}

- (NSNumber<RLMInt> *)value {
    verifyAttached(self);
    auto table = _row.get_table();
    if (table->is_null(_colIndex, _row.get_index())) {
        return nil;
    }
    return @(_row.get_table()->get_int(_colIndex, _row.get_index()));
}

- (void)incrementValueBy:(NSInteger)delta {
    verifyInWriteTransaction(self);
    auto table = _row.get_table();
    size_t rowIndex = _row.get_index();
    if (RLMObservationInfo *info = RLMGetObservationInfo(_object->_observationInfo, rowIndex, *_object->_info)) {
        info->willChange(_name);
        increment_nullable_int(table, _colIndex, rowIndex, delta);
        info->didChange(_name);
    } else {
        increment_nullable_int(table, _colIndex, rowIndex, delta);
    }
}

@end
