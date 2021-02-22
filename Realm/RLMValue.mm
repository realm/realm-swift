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

#pragma mark NSNumber

@implementation NSNumber (RLMValue)

- (RLMPropertyType)valueType {
    if (numberIsInteger(self)) {
        return RLMPropertyTypeInt;
    } else if (numberIsBool(self)) {
        return RLMPropertyTypeBool;
    } else if (numberIsFloat(self)) {
        return RLMPropertyTypeFloat;
    } else {
        return RLMPropertyTypeDouble;
    }
}

@end

@implementation NSNull (RLMValue)

- (RLMPropertyType)valueType {
    return RLMPropertyTypeAny;
}

@end

@implementation NSString (RLMValue)

- (RLMPropertyType)valueType {
    return RLMPropertyTypeString;
}

@end

@implementation NSData (RLMValue)

- (RLMPropertyType)valueType {
    return RLMPropertyTypeData;
}

@end

@implementation NSDate (RLMValue)

- (RLMPropertyType)valueType {
    return RLMPropertyTypeDate;
}

@end

@implementation RLMObject (RLMValue)

- (RLMPropertyType)valueType {
    return RLMPropertyTypeObject;
}

@end

@implementation RLMObjectBase (RLMValue)

- (RLMPropertyType)valueType {
    return RLMPropertyTypeObject;
}

@end

@implementation RLMObjectId (RLMValue)

- (RLMPropertyType)valueType {
    return RLMPropertyTypeObjectId;
}

@end

@implementation RLMDecimal128 (RLMValue)

- (RLMPropertyType)valueType {
    return RLMPropertyTypeDecimal128;
}

@end
