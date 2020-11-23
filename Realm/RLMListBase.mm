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
#import "RLMObjectSchema_Private.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"

@interface RLMArray (KVO)
- (NSArray *)objectsAtIndexes:(__unused NSIndexSet *)indexes;
@end

@implementation RLMListBase {
    std::unique_ptr<RLMObservationInfo> _observationInfo;
}

+ (RLMArray *)_unmanagedArray {
    return nil;
}

- (instancetype)init {
    return self = [super init];
}

- (instancetype)initWithArray:(RLMArray *)array {
    self = [super init];
    if (self) {
        __rlmArray = array;
    }
    return self;
}

- (RLMArray *)_rlmArray {
    if (!__rlmArray) {
        __rlmArray = self.class._unmanagedArray;
    }
    return __rlmArray;
}

- (id)valueForKey:(NSString *)key {
    return [self._rlmArray valueForKey:key];
}

- (id)valueForKeyPath:(NSString *)keyPath {
    return [self._rlmArray valueForKeyPath:keyPath];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    return [self._rlmArray countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
    return [self._rlmArray objectsAtIndexes:indexes];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    RLMEnsureArrayObservationInfo(_observationInfo, keyPath, self._rlmArray, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (BOOL)isEqual:(id)object {
    if (auto array = RLMDynamicCast<RLMListBase>(object)) {
        return !array._rlmArray.realm
        && ((self._rlmArray.count == 0 && array._rlmArray.count == 0) ||
            [self._rlmArray isEqual:array._rlmArray]);
    }
    return NO;
}

@end

@implementation RLMLinkingObjectsHandle {
    realm::TableKey _tableKey;
    realm::ObjKey _objKey;
    RLMClassInfo *_info;
    RLMRealm *_realm;
    RLMProperty *_property;

    RLMResults *_results;
}

- (instancetype)initWithObject:(RLMObjectBase *)object property:(RLMProperty *)prop {
    if (!(self = [super init])) {
        return nil;
    }
    auto& obj = object->_row;
    _tableKey = obj.get_table()->get_key();
    _objKey = obj.get_key();
    _info = object->_info;
    _realm = object->_realm;
    _property = prop;

    return self;
}

- (instancetype)initWithLinkingObjects:(RLMResults *)linkingObjects {
    if (!(self = [super init])) {
        return nil;
    }
    _realm = linkingObjects.realm;
    _results = linkingObjects;

    return self;
}

- (instancetype)freeze {
    RLMLinkingObjectsHandle *frozen = [[self.class alloc] init];
    frozen->_results = [self.results freeze];
    return frozen;
}

- (instancetype)thaw {
    RLMLinkingObjectsHandle *thawed = [[self.class alloc] init];
    thawed->_results = [self.results thaw];
    return thawed;
}

- (RLMResults *)results {
    if (_results) {
        return _results;
    }
    [_realm verifyThread];

    auto table = _realm.group.get_table(_tableKey);
    if (!table->is_valid(_objKey)) {
        @throw RLMException(@"Object has been deleted or invalidated.");
    }

    auto obj = _realm.group.get_table(_tableKey)->get_object(_objKey);
    auto& objectInfo = _realm->_info[_property.objectClassName];
    auto& linkOrigin = _info->objectSchema->computed_properties[_property.index].link_origin_property_name;
    auto linkingProperty = objectInfo.objectSchema->property_for_name(linkOrigin);
    realm::Results results(_realm->_realm, obj.get_backlink_view(objectInfo.table(), linkingProperty->column_key));
    _results = [RLMLinkingObjects resultsWithObjectInfo:objectInfo results:std::move(results)];
    _realm = nil;
    return _results;
}

@end
