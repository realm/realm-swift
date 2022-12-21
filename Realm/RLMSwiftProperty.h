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

#import <Foundation/Foundation.h>
#import <stdint.h>

@class RLMObjectBase, RLMArray, RLMSet;

#ifdef __cplusplus
extern "C" {
#endif

RLM_HEADER_AUDIT_BEGIN(nullability)

#define REALM_FOR_EACH_SWIFT_PRIMITIVE_TYPE(macro) \
    macro(bool, Bool, bool) \
    macro(double, Double, double) \
    macro(float, Float, float) \
    macro(int64_t, Int64, int)

#define REALM_FOR_EACH_SWIFT_OBJECT_TYPE(macro) \
    macro(NSString, String, string) \
    macro(NSDate, Date, date) \
    macro(NSData, Data, data) \
    macro(NSUUID, UUID, uuid) \
    macro(RLMDecimal128, Decimal128, decimal128) \
    macro(RLMObjectId, ObjectId, objectId)

#define REALM_SWIFT_PROPERTY_ACCESSOR(objc, swift, rlmtype) \
    objc RLMGetSwiftProperty##swift(RLMObjectBase *, uint16_t); \
    objc RLMGetSwiftProperty##swift##Optional(RLMObjectBase *, uint16_t, bool *); \
    void RLMSetSwiftProperty##swift(RLMObjectBase *, uint16_t, objc);
REALM_FOR_EACH_SWIFT_PRIMITIVE_TYPE(REALM_SWIFT_PROPERTY_ACCESSOR)
#undef REALM_SWIFT_PROPERTY_ACCESSOR

#define REALM_SWIFT_PROPERTY_ACCESSOR(objc, swift, rlmtype) \
    objc *_Nullable RLMGetSwiftProperty##swift(RLMObjectBase *, uint16_t); \
    void RLMSetSwiftProperty##swift(RLMObjectBase *, uint16_t, objc *_Nullable);
REALM_FOR_EACH_SWIFT_OBJECT_TYPE(REALM_SWIFT_PROPERTY_ACCESSOR)
#undef REALM_SWIFT_PROPERTY_ACCESSOR

id<RLMValue> _Nullable RLMGetSwiftPropertyAny(RLMObjectBase *, uint16_t);
void RLMSetSwiftPropertyAny(RLMObjectBase *, uint16_t, id<RLMValue>);
RLMObjectBase *_Nullable RLMGetSwiftPropertyObject(RLMObjectBase *, uint16_t);
void RLMSetSwiftPropertyNil(RLMObjectBase *, uint16_t);
void RLMSetSwiftPropertyObject(RLMObjectBase *, uint16_t, RLMObjectBase *_Nullable);

RLMArray *_Nonnull RLMGetSwiftPropertyArray(RLMObjectBase *obj, uint16_t);
RLMSet *_Nonnull RLMGetSwiftPropertySet(RLMObjectBase *obj, uint16_t);
RLMDictionary *_Nonnull RLMGetSwiftPropertyMap(RLMObjectBase *obj, uint16_t);

RLM_HEADER_AUDIT_END(nullability)

#ifdef __cplusplus
} // extern "C"
#endif
