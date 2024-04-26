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

#import "RLMValue.h"
#import "RLMUtil.hpp"

#pragma mark NSData

@implementation NSData (RLMValue)

- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeData;
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeData;
}

@end

#pragma mark NSDate

@implementation NSDate (RLMValue)

- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeDate;
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeDate;
}

@end

#pragma mark NSNumber

@implementation NSNumber (RLMValue)

- (RLMPropertyType)rlm_valueType {
    if ([self objCType][0] == 'c' && (self.intValue == 0 || self.intValue == 1)) {
        return RLMPropertyTypeBool;
    }
    else if (numberIsInteger(self)) {
        return RLMPropertyTypeInt;
    }
    else if (*@encode(float) == [self objCType][0]) {
        return RLMPropertyTypeFloat;
    }
    else if (*@encode(double) == [self objCType][0]) {
        return RLMPropertyTypeDouble;
    }
    else {
        @throw RLMException(@"Unknown numeric type on type RLMValue.");
    }
}

- (RLMAnyValueType)rlm_anyValueType {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (RLMAnyValueType)self.rlm_valueType;
#pragma clang diagnostic pop
}

@end

#pragma mark NSNull

@implementation NSNull (RLMValue)

- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeAny;
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeAny;
}

@end

#pragma mark NSString

@implementation NSString (RLMValue)

- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeString;
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeString;
}

@end

#pragma mark NSUUID

@implementation NSUUID (RLMValue)

- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeUUID;
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeUUID;
}

@end

#pragma mark RLMDecimal128

@implementation RLMDecimal128 (RLMValue)

- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeDecimal128;
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeDecimal128;
}

@end

#pragma mark RLMObjectBase

@implementation RLMObjectBase (RLMValue)

- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeObject;
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeObject;
}

@end

#pragma mark RLMObjectId

@implementation RLMObjectId (RLMValue)

- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeObjectId;
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeObjectId;
}

@end

#pragma mark Dictionary

@implementation NSDictionary (RLMValue)

- (RLMPropertyType)rlm_valueType {
    REALM_UNREACHABLE();
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeDictionary;
}

@end

@implementation RLMDictionary (RLMValue)

- (RLMPropertyType)rlm_valueType {
    REALM_UNREACHABLE();
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeDictionary;
}

@end

#pragma mark Array

@implementation NSArray (RLMValue)

- (RLMPropertyType)rlm_valueType {
    REALM_UNREACHABLE();
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeList;
}

@end

@implementation RLMArray (RLMValue)

- (RLMPropertyType)rlm_valueType {
    REALM_UNREACHABLE();
}

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeList;
}

@end
