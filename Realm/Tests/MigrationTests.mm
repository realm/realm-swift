//
//  MigrationTests.mm
//  Realm
//
//  Created by Ari Lazier on 6/24/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTestCase.h"

// private realm methods
@interface RLMRealm ()
+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError;
- (RLMSchema *)schema;
@end

@interface MigrationObject : RLMObject
@property NSString *stringCol;
@property int intCol;
@end

@interface MigrationTests : RLMTestCase

@end


@implementation MigrationTests


@end
