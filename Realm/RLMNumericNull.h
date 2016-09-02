//
//  RLMNumberDefault.h
//  Realm
//
//  Created by Realm on 8/30/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RLMNumericNull : NSNumber

- (instancetype)initWithObjCType:(const char *)objCType;

+ (instancetype)nullChar             NS_SWIFT_NAME(nullInt8());
+ (instancetype)nullUnsignedChar     NS_SWIFT_NAME(nullUInt8());
+ (instancetype)nullShort            NS_SWIFT_NAME(nullInt16());
+ (instancetype)nullUnsignedShort    NS_SWIFT_NAME(nullUInt16());
+ (instancetype)nullInt              NS_SWIFT_NAME(nullInt32());
+ (instancetype)nullUnsignedInt      NS_SWIFT_NAME(nullUInt32());
+ (instancetype)nullLong             NS_SWIFT_NAME(nullInt());
+ (instancetype)nullUnsignedLong     NS_SWIFT_NAME(nullUInt());
+ (instancetype)nullLongLong         NS_SWIFT_NAME(nullInt64());
+ (instancetype)nullUnsignedLongLong NS_SWIFT_NAME(nullUInt64());
+ (instancetype)nullFloat;
+ (instancetype)nullDouble;
+ (instancetype)nullBool;

@end
