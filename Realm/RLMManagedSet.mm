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

#import "RLMSet_Private.hpp"

#import "RLMAccessor.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema.h"
#import "RLMThreadSafeReference_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/set.hpp>

#import <realm/object-store/results.hpp>
#import <realm/object-store/shared_realm.hpp>

//#import <realm/table_view.hpp>
#import <objc/runtime.h>



@interface RLMManagedSetHandoverMetadata : NSObject
@property (nonatomic) NSString *parentClassName;
@property (nonatomic) NSString *key;
@end

@implementation RLMManagedSetHandoverMetadata
@end

@interface RLMManagedSet () <RLMThreadConfined_Private>
@end


//
// RLMSet implementation
//
@implementation RLMManagedSet {
@public
    realm::object_store::Set _backingSet;
    RLMRealm *_realm;
    RLMClassInfo *_objectInfo;
    RLMClassInfo *_ownerInfo;
    std::unique_ptr<RLMObservationInfo> _observationInfo;
}

- (RLMManagedSet *)initWithSet:(realm::object_store::Set &)set
                    parentInfo:(RLMClassInfo *)parentInfo
                      property:(__unsafe_unretained RLMProperty *const)property {
//    if (property.type == RLMPropertyTypeObject)
//        self = [self initWithObjectClassName:property.objectClassName];
//    else
//        self = [self initWithObjectType:property.type optional:property.optional];
//    if (self) {
//        _realm = parentInfo->realm;
//        // FIXME: Set needs link to realm
////        REALM_ASSERT(set.get_realm() == _realm->_realm);
//        _backingSet = std::move(set);
//        _ownerInfo = parentInfo;
//        if (property.type == RLMPropertyTypeObject)
//            _objectInfo = &parentInfo->linkTargetType(property.index);
//        else
//            _objectInfo = _ownerInfo;
//        _key = property.name;
//    }
//    return self;
}

- (RLMManagedSet *)initWithParent:(__unsafe_unretained RLMObjectBase *const)parentObject
                         property:(__unsafe_unretained RLMProperty *const)property {

//    __unsafe_unretained RLMRealm *const realm = parentObject->_realm;
//    auto col = parentObject->_info->tableColumn(property);
//    return [self initWithSet:realm::Set(realm->_realm, parentObject->_row, col)
//                  parentInfo:parentObject->_info
//                    property:property];
    return nil;
}

@end
