//
//  Performance.h
//  TightDbExample
//
//  Created by Bjarne Christiansen on 5/24/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Utils;
@interface Performance : NSObject


-(id)initWithUtils:(Utils *)utils;
- (void)testInsert;
- (void)testFetch;
- (void)testFetchAndIterate;
- (void)testUnqualifiedFetchAndIterate;
- (void)testWriteToDisk;
- (void)testFetchSparse;
@end
