#import "RLMTestCase.h"


@interface BaseCategoryTestObject : RLMObject
@property NSInteger intCol;
@end

// Class extension, adding one more column
@interface BaseCategoryTestObject ()
@property (nonatomic, copy) NSString *stringCol;
@end

@implementation BaseCategoryTestObject
@end


@interface CategoryTest : RLMTestCase

@end
@implementation CategoryTest



- (void)testCategory
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    BaseCategoryTestObject *bObject = [[BaseCategoryTestObject alloc ] init];
    bObject.intCol = 1;
    bObject.stringCol = @"stringVal";
    [realm addObject:bObject];
    [realm commitWriteTransaction];
    
    
    BaseCategoryTestObject *objectFromRealm = [BaseCategoryTestObject allObjects][0];
    XCTAssertEqual(1, objectFromRealm.intCol, @"Should be 1");
    XCTAssertEqualObjects(@"stringVal", objectFromRealm.stringCol, @"Should be stringVal");
}

@end
