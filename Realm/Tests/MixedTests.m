#import "RLMTestCase.h"
#import "XCTestCase+AsyncTesting.h"

@interface MixedObject : RLMObject
@property (nonatomic, assign) BOOL hired;
@property (nonatomic, strong) id other;
@property (nonatomic, assign) NSInteger age;
@end

@implementation MixedObject
@end


@interface MixedTests : RLMTestCase
@property (nonatomic, strong) RLMRealm *realm;
@end

@implementation MixedTests

#pragma mark - commons

- (void)setUp {
    [super setUp];
    _realm = [self realmWithTestPath];
}

- (void)tearDown {
    _realm = nil;
    [super tearDown];
}

#pragma mark - Tests

- (void)testMixedInsert {
    const char *data = "Hello World";

    // FIXME: add object with subtable
    [_realm beginWriteTransaction];
    [MixedObject createInRealm:_realm withObject:@[@YES, @"Jens", @50]];
    [MixedObject createInRealm:_realm withObject:@[@YES, @10, @52]];
    [MixedObject createInRealm:_realm withObject:@[@YES, @3.1f, @53]];
    [MixedObject createInRealm:_realm withObject:@[@YES, @3.1, @54]];
    [MixedObject createInRealm:_realm withObject:@[@YES, [NSDate date], @55]];
    [MixedObject createInRealm:_realm withObject:@[@YES, [NSData dataWithBytes:(void *)data length:strlen(data)], @56]];
    [_realm commitWriteTransaction];

    RLMArray *objects = [_realm allObjects:MixedObject.className];
    XCTAssertEqual(objects.count, (NSUInteger)6, @"6 rows excepted");
    XCTAssertTrue([[objects objectAtIndex:0] isKindOfClass:[MixedObject class]], @"MixedObject expected");
    XCTAssertTrue([[objects objectAtIndex:0][@"other"] isKindOfClass:[NSString class]], @"NSString expected");
    XCTAssertTrue([[objects objectAtIndex:0][@"other"] isEqualToString:@"Jens"], @"'Jens' expected");

    XCTAssertTrue([[objects objectAtIndex:1][@"other"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertEqual([[objects objectAtIndex:1][@"other"] longLongValue], (long long)10, @"'10' expected");

    XCTAssertTrue([[objects objectAtIndex:2][@"other"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertEqual([[objects objectAtIndex:2][@"other"] floatValue], (float)3.1, @"'3.1' expected");

    XCTAssertTrue([[objects objectAtIndex:3][@"other"] isKindOfClass:[NSNumber class]], @"NSNumber expected");
    XCTAssertEqual([[objects objectAtIndex:3][@"other"] doubleValue], (double)3.1, @"'3.1' expected");

    XCTAssertTrue([[objects objectAtIndex:4][@"other"] isKindOfClass:[NSDate class]], @"NSDate expected");

    XCTAssertTrue([[objects objectAtIndex:5][@"other"] isKindOfClass:[NSData class]], @"NSData expected");
}

- (void)testMixedValidate {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    XCTAssertThrows(([MixedObject createInRealm:realm withObject:@[@YES, @[@1, @2], @7]]), @"Mixed cannot be an NSArray");
    XCTAssertThrows(([MixedObject createInRealm:realm withObject:@[@YES, @{@"key": @7}, @11]]), @"Mixed cannot be an NSDictionary");

    XCTAssertEqual([MixedObject allObjects].count, (NSUInteger)0, @"0 rows expected");
    [realm commitWriteTransaction];
}



@end
