//
//  RLMTestDataGenerator.h
//  Realm
//
//  Created by Gustaf Kugelberg on 26/08/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLMRealm;

@interface RLMTestDataGenerator : NSObject

+(BOOL)createRealmAtUrl:(NSURL *)url withClassesNamed:(NSArray *)testClassNames elementCount:(NSUInteger)objectCount;

@end