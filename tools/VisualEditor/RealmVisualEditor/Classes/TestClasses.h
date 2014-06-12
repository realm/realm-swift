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

@property NSInteger integerValue;
@property NSString *stringValue;

@end

RLM_ARRAY_TYPE(RealmTestClass0)

@interface RealmTestClass1 : RLMObject

@property NSInteger integerValue;
@property BOOL boolValue;
@property float floatValue;
@property double doubleValue;
@property NSString *stringValue;
@property NSDate *dateValue;
@property RLMArray<RealmTestClass0> *arrayReference;

@end

@interface RealmTestClass2 : RLMObject

@property NSInteger integerValue;
@property BOOL boolValue;
@property RealmTestClass1 *objectReference;

@end

