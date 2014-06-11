//
//  TestClasses.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 11/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface RealmTestClass0 : RLMObject

@property (nonatomic, readonly) NSInteger integerValue;
@property (nonatomic, readonly) NSString *stringValue;

+ (instancetype)instanceWithInt:(NSInteger)integerValue string:(NSString *)stringValue;

@end

RLM_ARRAY_TYPE(RealmTestClass0)

@interface RealmTestClass1 : RLMObject

@property (nonatomic, readonly) NSInteger integerValue;
@property (nonatomic, readonly) BOOL boolValue;
@property (nonatomic, readonly) float floatValue;
@property (nonatomic, readonly) float doubleValue;
@property (nonatomic, readonly) NSString *stringValue;
@property (nonatomic, readonly) NSDate *dateValue;
@property (nonatomic, readonly) RLMArray<RealmTestClass0> *arrayReference;

+ (instancetype)instanceWithInt:(NSInteger)integerValue bool:(BOOL)boolValue float:(float)floatValue double:(double)doubleValue string:(NSString *)stringValue date:(NSDate *)dateValue arrayRef:(RLMArray<RealmTestClass0> *)arrayRef;

@end

@interface RealmTestClass2 : RLMObject

@property (nonatomic, readonly) NSInteger integerValue;
@property (nonatomic, readonly) BOOL boolValue;
@property (nonatomic, readonly) RealmTestClass1 *objectReference;

+ (instancetype)instanceWithInt:(NSInteger)integerValue bool:(BOOL)boolValue objectRef:(RealmTestClass1 *)objRef;

@end

