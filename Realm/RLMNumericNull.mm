//
//  RLMNumberDefault.m
//  Realm
//
//  Created by Realm on 8/30/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMNumericNull.h"
#import "RLMUtil.hpp"

@implementation RLMNumericNull

@synthesize objCType = _objCType;

- (instancetype)initWithObjCType:(const char *)objCType {
    if (self = [super init]) {
        _objCType = objCType;
    }
    return self;
}

+ (instancetype)nullChar {
    return [[self alloc] initWithObjCType:@encode(char)];
}
+ (instancetype)nullUnsignedChar {
    return [[self alloc] initWithObjCType:@encode(unsigned char)];
}
+ (instancetype)nullShort {
    return [[self alloc] initWithObjCType:@encode(short)];
}
+ (instancetype)nullUnsignedShort {
    return [[self alloc] initWithObjCType:@encode(unsigned short)];
}
+ (instancetype)nullInt {
    return [[self alloc] initWithObjCType:@encode(int)];
}
+ (instancetype)nullUnsignedInt {
    return [[self alloc] initWithObjCType:@encode(unsigned int)];
}
+ (instancetype)nullLong {
    return [[self alloc] initWithObjCType:@encode(long)];
}
+ (instancetype)nullUnsignedLong {
    return [[self alloc] initWithObjCType:@encode(unsigned long)];
}
+ (instancetype)nullLongLong {
    return [[self alloc] initWithObjCType:@encode(long long)];
}
+ (instancetype)nullUnsignedLongLong {
    return [[self alloc] initWithObjCType:@encode(unsigned long long)];
}
+ (instancetype)nullFloat {
    return [[self alloc] initWithObjCType:@encode(float)];
}
+ (instancetype)nullDouble {
    return [[self alloc] initWithObjCType:@encode(double)];
}
+ (instancetype)nullBool {
    return [[self alloc] initWithObjCType:@encode(bool)];
}
+ (instancetype)nullInteger {
    return [[self alloc] initWithObjCType:@encode(NSInteger)];
}
+ (instancetype)nullUnsignedInteger {
    return [[self alloc] initWithObjCType:@encode(NSUInteger)];
}

- (char)charValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (unsigned char)unsignedCharValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (short)shortValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (unsigned short)unsignedShortValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (int)intValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (unsigned int)unsignedIntValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (long)longValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (unsigned long)unsignedLongValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (long long)longLongValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (unsigned long long)unsignedLongLongValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (float)floatValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (double)doubleValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (BOOL)boolValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (NSInteger)integerValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}
- (NSUInteger)unsignedIntegerValue {
    @throw RLMException(@"Unexpected call to accessor method on `RLMNumericNull`.");
}

- (NSString *)stringValue {
    return @"<null>";
}

-(NSString *)description {
    return self.stringValue;
}

@end
