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

#import <Realm/RLMArray.h>
#import <Realm/RLMConstants.h>
#import <Realm/RLMDecimal128.h>
#import <Realm/RLMDictionary.h>
#import <Realm/RLMObject.h>
#import <Realm/RLMObjectBase.h>
#import <Realm/RLMObjectId.h>
#import <Realm/RLMProperty.h>

#pragma mark RLMValue

/**
 RLMValue is a property type which represents a polymorphic Realm value. This is similar to the usage of
 `AnyObject` / `Any` in Swift.
```
 // A property on `MyObject`
 @property (nonatomic) id<RLMValue> myAnyValue;

 // A property on `AnotherObject`
 @property (nonatomic) id<RLMValue> myAnyValue;

 MyObject *myObject = [MyObject createInRealm:realm withValue:@[]];
 myObject.myAnyValue = @1234; // underlying type is NSNumber.
 myObject.myAnyValue = @"hello"; // underlying type is NSString.
 AnotherObject *anotherObject = [AnotherObject createInRealm:realm withValue:@[]];
 myObject.myAnyValue = anotherObject; // underlying type is RLMObject.
```
 The following types conform to RLMValue:

 `NSData`
 `NSDate`
 `NSNull`
 `NSNumber`
 `NSUUID`
 `NSString`
 `RLMObject
 `RLMObjectId`
 `RLMDecimal128`
 `RLMDictionary`
 `RLMArray`
 `NSArray`
 `NSDictionary`
 */
@protocol RLMValue

/// Describes the type of property stored.
@property (readonly) RLMAnyValueType rlm_valueType __attribute__((deprecated("Use `rlm_anyValueType` instead, which includes collection types as well")));
/// Describes the type of property stored.
@property (readonly) RLMAnyValueType rlm_anyValueType;

@end

/// :nodoc:
@interface NSNull (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface NSNumber (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface NSString (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface NSData (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface NSDate (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface NSUUID (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface RLMDecimal128 (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface RLMObjectBase (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface RLMObjectId (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface NSDictionary (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface NSArray (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface RLMArray (RLMValue)<RLMValue>
@end

/// :nodoc:
@interface RLMDictionary (RLMValue)<RLMValue>
@end
