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

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeData;
}

@end

#pragma mark NSDate

@implementation NSDate (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeDate;
}

@end

#pragma mark NSNumber

@implementation NSNumber (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    if ([self objCType][0] == 'c' && (self.intValue == 0 || self.intValue == 1)) {
        return RLMMixedValueTypeBool;
    }
    else if (numberIsInteger(self)) {
        return RLMMixedValueTypeInt;
    }
    else if (*@encode(float) == [self objCType][0]) {
        return RLMMixedValueTypeFloat;
    }
    else if (*@encode(double) == [self objCType][0]) {
        return RLMMixedValueTypeDouble;
    }
    else {
        @throw RLMException(@"Unknown numeric type on type RLMValue.");
    }
}

@end

#pragma mark NSNull

@implementation NSNull (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeAny;
}

@end

#pragma mark NSString

@implementation NSString (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeString;
}

@end

#pragma mark NSUUID

@implementation NSUUID (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeUUID;
}

@end

#pragma mark RLMDecimal128

@implementation RLMDecimal128 (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeDecimal128;
}

@end

#pragma mark RLMObjectBase

@implementation RLMObjectBase (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeObject;
}

@end

#pragma mark RLMObjectId

@implementation RLMObjectId (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeObjectId;
}

@end

#pragma mark Dictionary

@implementation NSDictionary (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeDictionary;
}

@end

@implementation RLMDictionary (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeDictionary;
}

@end

#pragma mark Array

@implementation NSArray (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeList;
}

@end

@implementation RLMArray (RLMValue)

- (RLMMixedValueType)rlm_valueType {
    return RLMMixedValueTypeList;
}

@end
