//
//  Performance.h
//  TightDbExample
//
//  Created by Bjarne Christiansen on 5/24/12.
//

#import <Foundation/Foundation.h>

@class Utils;
@interface Performance : NSObject


-(id)initWithUtils:(Utils *)utils;
- (void)testInsert;
- (void)testLinearInt;
- (void)testLinearString;
- (void)testMultipleConditions;
- (void)testFetchAndIterate;
- (void)testUnqualifiedFetchAndIterate;
- (void)testWriteToDisk;
- (void)testWriteTransaction;
@end
