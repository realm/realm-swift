//
//  RLMSchema_Private.h
//  Realm
//
//  Created by Ari Lazier on 5/19/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMSchema.h"

@class RLMRealm;

// RLMSchema private interface
@interface RLMSchema ()

// mapping of className to tableName
@property (nonatomic, readonly) NSMutableDictionary *tableNamesForClass;

// schema based on runtime objects
+(instancetype)sharedSchema;

// schema based on tables in a Realm
+(instancetype)dynamicSchemaFromRealm:(RLMRealm *)realm;

// get object class to use for a given class name
-(Class)objectClassForClassName:(NSString *)className;

@end
