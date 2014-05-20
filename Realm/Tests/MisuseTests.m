////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"


@interface SimpleWrongObject : RLMObject
@property (nonatomic, assign) int *intCol; // Wrong with * but possible
@end

@implementation SimpleWrongObject
@end


@interface MisuseTests : RLMTestCase

@end

@implementation MisuseTests


-(void)testWrongObject
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    //XCTAssertThrows([SimpleWrongObject createInRealm:realm withObject:nil], @"Wrong defined object");
    
    [realm commitWriteTransaction];
}



@end
