////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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
#import "RLMNativeObjectSupport.h"

static const uint8_t RLMNativeObjectSentinalBytes[] = {0x89, 0x52, 0x4E, 0x4F}; // ?RNO

static NSString * const kRLMNativeObjectDataTypeKey         = @"type";
static NSString * const kRLMNativeObjectDataClassNameKey    = @"className";
static NSString * const kRLMNativeObjectDataObjectValueKey  = @"objectValue";

static NSString * const kRLMNativeObjectDataTypeValue       = @"RLMNativeObject";

BOOL _RLMDataHasNativeObjectSentinalPrefix(NSData *data) {
    size_t sentinalLength = sizeof(RLMNativeObjectSentinalBytes);
    if ([data length] <= sentinalLength) return NO;
    
    NSData *prefix = [data subdataWithRange:NSMakeRange(0, sentinalLength)];
    NSData *sentinal = [NSData dataWithBytes:RLMNativeObjectSentinalBytes length:sentinalLength];

    return [prefix isEqualToData:sentinal];
}

NSDictionary * _RLMStorageFromData(NSData *data) {
    if (!_RLMDataHasNativeObjectSentinalPrefix(data)) return nil;
    NSDictionary *storage = nil;
    @try {
        size_t sentinalLength = sizeof(RLMNativeObjectSentinalBytes);
        data = [data subdataWithRange:NSMakeRange(sentinalLength, [data length] - sentinalLength)];
        storage = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) {
        return nil;
    }

    return storage;
}

BOOL RLMNativeObjectSupportsArchiving(id nativeObject) {
    return [nativeObject conformsToProtocol:@protocol(NSCoding)];
}

BOOL RLMDataContainsNativeObject(NSData *data) {
    NSDictionary *storage = _RLMStorageFromData(data);
    if (!storage) return NO;
    if (![kRLMNativeObjectDataTypeValue isEqualToString:[storage objectForKey:kRLMNativeObjectDataTypeKey]]) return NO;
    return YES;
}

NSData * RLMDataFromNativeObject(id <NSObject, NSCoding> nativeObject, NSString *className) {
    NSMutableData *prefix = [[NSMutableData alloc] initWithBytes:RLMNativeObjectSentinalBytes length:sizeof(RLMNativeObjectSentinalBytes)];

    NSDictionary *storage = @{kRLMNativeObjectDataTypeKey:kRLMNativeObjectDataTypeValue,
                              kRLMNativeObjectDataClassNameKey: className,
                              kRLMNativeObjectDataObjectValueKey: nativeObject ? : [NSNull null]};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:storage];

    [prefix appendData:data];
    return [prefix copy];
}

id<NSCoding> RLMNativeObjectFromData(NSData *data) {
    NSDictionary *storage = _RLMStorageFromData(data);
    if (!storage) return nil;

    if (![kRLMNativeObjectDataTypeValue isEqualToString:[storage objectForKey:kRLMNativeObjectDataTypeKey]]) return nil;
    id nativeObject = [storage objectForKey:kRLMNativeObjectDataObjectValueKey];
    
    return nativeObject == [NSNull null] ? nil : nativeObject;
    
}

NSString * RLMNativeObjectClassNameFromData(NSData *data) {
    NSDictionary *storage = _RLMStorageFromData(data);
    if (!storage) return nil;
    
    if (![kRLMNativeObjectDataTypeValue isEqualToString:[storage objectForKey:kRLMNativeObjectDataTypeKey]]) return nil;

    return [storage objectForKey:kRLMNativeObjectDataClassNameKey];
}

