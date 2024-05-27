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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeData;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeData;
}

@end

#pragma mark NSDate

@implementation NSDate (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeDate;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeDate;
}

@end

#pragma mark NSNumber

@implementation NSNumber (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
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
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    if ([self objCType][0] == 'c' && (self.intValue == 0 || self.intValue == 1)) {
        return RLMAnyValueTypeBool;
    }
    else if (numberIsInteger(self)) {
        return RLMAnyValueTypeInt;
    }
    else if (*@encode(float) == [self objCType][0]) {
        return RLMAnyValueTypeFloat;
    }
    else if (*@encode(double) == [self objCType][0]) {
        return RLMAnyValueTypeDouble;
    }
    else {
        @throw RLMException(@"Unknown numeric type on type RLMValue.");
    }
}

@end

#pragma mark NSNull

@implementation NSNull (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeAny;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeAny;
}

@end

#pragma mark NSString

@implementation NSString (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeString;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeString;
}

@end

#pragma mark NSUUID

@implementation NSUUID (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeUUID;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeUUID;
}

@end

#pragma mark RLMDecimal128

@implementation RLMDecimal128 (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeDecimal128;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeDecimal128;
}

@end

#pragma mark RLMObjectBase

@implementation RLMObjectBase (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeObject;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeObject;
}

@end

#pragma mark RLMObjectId

@implementation RLMObjectId (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeObjectId;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeObjectId;
}

@end

#pragma mark Dictionary

@implementation NSDictionary (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeAny;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeDictionary;
}

@end

@implementation RLMDictionary (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType { return RLMPropertyTypeAny;
    return RLMPropertyTypeAny;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeDictionary;
}

@end

#pragma mark Array

@implementation NSArray (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeAny;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeList;
}

@end

@implementation RLMArray (RLMValue)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (RLMPropertyType)rlm_valueType {
    return RLMPropertyTypeAny;
}
#pragma clang diagnostic pop

- (RLMAnyValueType)rlm_anyValueType {
    return RLMAnyValueTypeList;
}

@end
