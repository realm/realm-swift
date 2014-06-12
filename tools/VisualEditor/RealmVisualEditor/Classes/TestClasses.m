//
//  TestClasses.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 11/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "TestClasses.h"

@implementation RealmTestClass0

+ (instancetype)instanceWithInt:(NSInteger)integerValue string:(NSString *)stringValue
{
    RealmTestClass0 *result = [[RealmTestClass0 alloc] init];
    result->_integerValue = integerValue;
    result->_stringValue = stringValue;
    return result;
}

@end

@implementation RealmTestClass1

+ (instancetype)instanceWithInt:(NSInteger)integerValue bool:(BOOL)boolValue float:(float)floatValue double:(double)doubleValue string:(NSString *)stringValue date:(NSDate *)dateValue arrayRef:(RLMArray<RealmTestClass0> *)arrayRef
{
    RealmTestClass1 *result = [[RealmTestClass1 alloc] init];
    result->_integerValue = integerValue;
    result->_boolValue = boolValue;
    result->_floatValue = floatValue;
    result->_doubleValue = doubleValue;
    result->_stringValue = stringValue;
    result->_dateValue = dateValue;
    return result;
}

@end

@implementation RealmTestClass2

+ (instancetype)instanceWithInt:(NSInteger)integerValue bool:(BOOL)boolValue objectRef:(RealmTestClass1 *)objRef
{
    RealmTestClass2 *result = [[RealmTestClass2 alloc] init];
    result->_integerValue = integerValue;
    result->_boolValue = boolValue;
    result->_objectReference = objRef;
    return result;
}

@end

