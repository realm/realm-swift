////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"
#import "RLMPredicateUtil.h"

#pragma mark - Test Objects

#pragma mark DefaultObject

@interface DefaultObject : RLMObject
@property int       intCol;
@property float     floatCol;
@property double    doubleCol;
@property BOOL      boolCol;
@property NSDate   *dateCol;
@property NSString *stringCol;
@property NSData   *binaryCol;
@property id        mixedCol;
@end

@implementation DefaultObject
+ (NSDictionary *)defaultPropertyValues
{
    NSString *binaryString = @"binary";
    NSData *binaryData = [binaryString dataUsingEncoding:NSUTF8StringEncoding];
    
    return @{@"intCol" : @12,
             @"floatCol" : @88.9f,
             @"doubleCol" : @1002.892,
             @"boolCol" : @YES,
             @"dateCol" : [NSDate dateWithTimeIntervalSince1970:999999],
             @"stringCol" : @"potato",
             @"binaryCol" : binaryData,
             @"mixedCol" : @"foo"};
}
@end

#pragma mark IgnoredURLObject

@interface IgnoredURLObject : RLMObject
@property NSString *name;
@property NSURL *url;
@end

@implementation IgnoredURLObject
+ (NSArray *)ignoredProperties
{
    return @[@"url"];
}
@end

#pragma mark IndexedObject

@interface IndexedObject : RLMObject
@property NSString *name;
@property NSInteger age;
@end

@implementation IndexedObject
+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName
{
    RLMPropertyAttributes superAttributes = [super attributesForProperty:propertyName];
    if ([propertyName isEqualToString:@"name"]) {
        superAttributes |= RLMPropertyAttributeIndexed;
    }
    return superAttributes;
}
@end

#pragma mark - Private

@interface RLMRealm ()
@property (nonatomic) RLMSchema *schema;
@end

#pragma mark - Tests

@interface ObjectTests : RLMTestCase
@end

@implementation ObjectTests

-(void)testObjectInit
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // Init object before adding to realm
    EmployeeObject *soInit = [[EmployeeObject alloc] init];
    soInit.name = @"Peter";
    soInit.age = 30;
    soInit.hired = YES;
    [realm addObject:soInit];
    
    // Create object while adding to realm using NSArray
    EmployeeObject *soUsingArray = [EmployeeObject createInRealm:realm withObject:@[@"John", @40, @NO]];
    
    // Create object while adding to realm using NSDictionary
    EmployeeObject *soUsingDictionary = [EmployeeObject createInRealm:realm withObject:@{@"name": @"Susi", @"age": @25, @"hired": @YES}];
    
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(soInit.name, @"Peter", @"Name should be Peter");
    XCTAssertEqual(soInit.age, 30, @"Age should be 30");
    XCTAssertEqual(soInit.hired, YES, @"Hired should YES");
    
    XCTAssertEqualObjects(soUsingArray.name, @"John", @"Name should be John");
    XCTAssertEqual(soUsingArray.age, 40, @"Age should be 40");
    XCTAssertEqual(soUsingArray.hired, NO, @"Hired should NO");
    
    XCTAssertEqualObjects(soUsingDictionary.name, @"Susi", @"Name should be Susi");
    XCTAssertEqual(soUsingDictionary.age, 25, @"Age should be 25");
    XCTAssertEqual(soUsingDictionary.hired, YES, @"Hired should YES");
    
    XCTAssertThrowsSpecificNamed([soInit JSONString], NSException, @"RLMNotImplementedException", @"Not yet implemented");
}

-(void)testObjectInitWithObjectTypeArray
{
    EmployeeObject *obj1 = [[EmployeeObject alloc] initWithObject:@[@"Peter", @30, @YES]];
    
    XCTAssertEqualObjects(obj1.name, @"Peter", @"Names should be equal");
    XCTAssertEqual(obj1.age, 30, @"Age should be equal");
    XCTAssertEqual(obj1.hired, YES, @"Hired should be equal");
    
    // Add to realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    [realm commitWriteTransaction];
    
    RLMArray *all = [EmployeeObject allObjects];
    EmployeeObject *fromRealm = all.firstObject;
    
    XCTAssertEqualObjects(fromRealm.name, @"Peter", @"Names should be equal");
    XCTAssertEqual(fromRealm.age, 30, @"Age should be equal");
    XCTAssertEqual(fromRealm.hired, YES, @"Hired should be equal");
    
    XCTAssertThrows(([[EmployeeObject alloc] initWithObject:@[@"Peter", @30]]), @"To few arguments");
    XCTAssertThrows(([[EmployeeObject alloc] initWithObject:@[@YES, @"Peter", @30]]), @"Wrong arguments");
    XCTAssertThrows(([[EmployeeObject alloc] initWithObject:@[]]), @"empty arguments");
}

-(void)testObjectInitWithObjectTypeDictionary
{
    EmployeeObject *obj1 = [[EmployeeObject alloc] initWithObject:@{@"name": @"Susi", @"age": @25, @"hired": @YES}];
    
    XCTAssertEqualObjects(obj1.name, @"Susi", @"Names should be equal");
    XCTAssertEqual(obj1.age, 25, @"Age should be equal");
    XCTAssertEqual(obj1.hired, YES, @"Hired should be equal");
    
    // Add to realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addObject:obj1];
    [realm commitWriteTransaction];
    
    RLMArray *all = [EmployeeObject allObjects];
    EmployeeObject *fromRealm = all.firstObject;
    
    XCTAssertEqualObjects(fromRealm.name, @"Susi", @"Names should be equal");
    XCTAssertEqual(fromRealm.age, 25, @"Age should be equal");
    XCTAssertEqual(fromRealm.hired, YES, @"Hired should be equal");
    
    
    EmployeeObject *objDefault = [[EmployeeObject alloc] initWithObject:@{}];
    XCTAssertNil(objDefault.name, @"nil string is default for String property");
    XCTAssertEqual(objDefault.age, 0, @"0 is default for int property");
    XCTAssertEqual(objDefault.hired, NO, @"No is default for Bool property");
}

-(void)testObjectInitWithObjectTypeOther
{
    XCTAssertThrows([[EmployeeObject alloc] initWithObject:@"StringObject"], @"Not an array or dictionary");
    XCTAssertThrows([[EmployeeObject alloc] initWithObject:nil], @"Not an array or dictionary");
}


- (void)testObjectSubscripting
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    IntObject *obj0 = [IntObject createInRealm:realm withObject:@[@10]];
    IntObject *obj1 = [IntObject createInRealm:realm withObject:@[@20]];
    [realm commitWriteTransaction];

    XCTAssertEqual(obj0.intCol, 10,  @"integer should be 10");
    XCTAssertEqual(obj1.intCol, 20, @"integer should be 20");

    [realm beginWriteTransaction];
    obj0.intCol = 7;
    [realm commitWriteTransaction];

    XCTAssertEqual(obj0.intCol, 7,  @"integer should be 7");
}

- (void)testKeyedSubscripting
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    EmployeeObject *obj0 = [EmployeeObject createInRealm:realm withObject:@{@"name" : @"Test1", @"age" : @24, @"hired": @NO}];
    EmployeeObject *obj1 = [EmployeeObject createInRealm:realm withObject:@{@"name" : @"Test2", @"age" : @25, @"hired": @YES}];
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(obj0[@"name"], @"Test1",  @"Name should be Test1");
    XCTAssertEqualObjects(obj1[@"name"], @"Test2", @"Name should be Test1");
    
    [realm beginWriteTransaction];
    obj0[@"name"] = @"newName";
    [realm commitWriteTransaction];
    
    XCTAssertEqualObjects(obj0[@"name"], @"newName",  @"Name should be newName");
}

- (void)testValidOperatorsInNumericComparison:(NSString *) comparisonType
                              withProposition:(BOOL(^)(NSPredicateOperatorType)) proposition
{
    XCTAssert(proposition(NSLessThanPredicateOperatorType),
              @"< operator in %@ comparison.", comparisonType);
    XCTAssert(proposition(NSLessThanOrEqualToPredicateOperatorType),
              @"<= or =< operator in %@ comparison.", comparisonType);
    XCTAssert(proposition(NSGreaterThanPredicateOperatorType),
              @"> operator in %@ comparison.", comparisonType);
    XCTAssert(proposition(NSGreaterThanOrEqualToPredicateOperatorType),
              @">= or => operator in %@ comparison.", comparisonType);
    XCTAssert(proposition(NSEqualToPredicateOperatorType),
              @"= or == operator in %@ comparison.", comparisonType);
    XCTAssert(proposition(NSNotEqualToPredicateOperatorType),
              @"<> or != operator in %@ comparison.", comparisonType);
}

- (void)testValidOperatorsInIntegerComparison
{
    BOOL (^isEmpty)(NSPredicateOperatorType) = [RLMPredicateUtil isEmptyIntColPredicate];
    [self testValidOperatorsInNumericComparison:@"integer" withProposition:isEmpty];
}

- (void)testValidOperatorsInFloatComparison
{
    BOOL (^isEmpty)(NSPredicateOperatorType) = [RLMPredicateUtil isEmptyFloatColPredicate];
    [self testValidOperatorsInNumericComparison:@"float" withProposition:isEmpty];
}

- (void)testValidOperatorsInDoubleComparison
{
    BOOL (^isEmpty)(NSPredicateOperatorType) = [RLMPredicateUtil isEmptyDoubleColPredicate];
    [self testValidOperatorsInNumericComparison:@"double" withProposition:isEmpty];
}

- (void)testValidOperatorsInDateComparison
{
    BOOL (^isEmpty)(NSPredicateOperatorType) = [RLMPredicateUtil isEmptyDateColPredicate];
    [self testValidOperatorsInNumericComparison:@"date" withProposition:isEmpty];
}

- (void)testInvalidOperatorsInNumericComparison:(NSString *) comparisonType
                                withProposition:(BOOL(^)(NSPredicateOperatorType)) proposition
{
    NSString *name = @"filterWithPredicate:orderedBy: - Invalid operator type";

    XCTAssertThrowsSpecificNamed(proposition(NSMatchesPredicateOperatorType),
                                 NSException, name,
                                 @"MATCHES operator invalid in %@ comparison.", comparisonType);
    XCTAssertThrowsSpecificNamed(proposition(NSLikePredicateOperatorType),
                                 NSException, name,
                                 @"LIKE operator invalid in %@ comparison.", comparisonType);
    XCTAssertThrowsSpecificNamed(proposition(NSBeginsWithPredicateOperatorType),
                                 NSException, name,
                                 @"BEGINSWITH operator invalid in %@ comparison.", comparisonType);
    XCTAssertThrowsSpecificNamed(proposition(NSEndsWithPredicateOperatorType),
                                 NSException, name,
                                 @"ENDSWITH operator invalid in %@ comparison.", comparisonType);
    XCTAssertThrowsSpecificNamed(proposition(NSInPredicateOperatorType),
                                 NSException, name,
                                 @"IN operator invalid in %@ comparison.", comparisonType);
    XCTAssertThrowsSpecificNamed(proposition(NSContainsPredicateOperatorType),
                                 NSException, name,
                                 @"CONTAINS operator invalid in %@ comparison.", comparisonType);
}

- (void)testInvalidOperatorsInIntegerComparison
{
    BOOL (^isEmpty)(NSPredicateOperatorType) = [RLMPredicateUtil isEmptyIntColPredicate];
    [self testInvalidOperatorsInNumericComparison:@"integer" withProposition:isEmpty];
}

- (void)testInvalidOperatorsInFloatComparison
{
    BOOL (^isEmpty)(NSPredicateOperatorType) = [RLMPredicateUtil isEmptyFloatColPredicate];
    [self testInvalidOperatorsInNumericComparison:@"float" withProposition:isEmpty];
}

- (void)testInvalidOperatorsInDoubleComparison
{
    BOOL (^isEmpty)(NSPredicateOperatorType) = [RLMPredicateUtil isEmptyDoubleColPredicate];
    [self testInvalidOperatorsInNumericComparison:@"double" withProposition:isEmpty];
}

- (void)testInvalidOperatorsInDateComparison
{
    BOOL (^isEmpty)(NSPredicateOperatorType) = [RLMPredicateUtil isEmptyDateColPredicate];
    [self testInvalidOperatorsInNumericComparison:@"date" withProposition:isEmpty];
}

- (void)testCustomSelectorsInNumericComparison:(NSString *) comparisonType
                               withProposition:(BOOL(^)()) proposition
{
    XCTAssertThrowsSpecificNamed(proposition(), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"Custom selector invalid in %@ comparison.", comparisonType);
}

- (void)testCustomSelectorsInIntegerComparison
{
    BOOL (^isEmpty)() = [RLMPredicateUtil alwaysEmptyIntColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"integer" withProposition:isEmpty];
}

- (void)testCustomSelectorsInFloatComparison
{
    BOOL (^isEmpty)() = [RLMPredicateUtil alwaysEmptyFloatColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"float" withProposition:isEmpty];
}

- (void)testCustomSelectorsInDoubleComparison
{
    BOOL (^isEmpty)() = [RLMPredicateUtil alwaysEmptyDoubleColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"double" withProposition:isEmpty];
}

- (void)testCustomSelectorsInDateComparison
{
    BOOL (^isEmpty)() = [RLMPredicateUtil alwaysEmptyDateColSelectorPredicate];
    [self testCustomSelectorsInNumericComparison:@"date" withProposition:isEmpty];
}

- (void)testBooleanPredicate
{
    XCTAssertEqual([BoolObject objectsWithPredicateFormat:@"boolCol == TRUE"].count,
                   (NSUInteger)0, @"== operator in bool predicate.");
    XCTAssertEqual([BoolObject objectsWithPredicateFormat:@"boolCol != TRUE"].count,
                   (NSUInteger)0, @"== operator in bool predicate.");

    XCTAssertThrowsSpecificNamed([BoolObject objectsWithPredicateFormat:@"boolCol >= TRUE"],
                                 NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"Invalid operator in bool predicate.");
}

- (void)testStringComparisonInPredicate
{
    // First, supported operators and options.
    // Make sure that case-sensitivity is handled the right way round.
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withObject:(@[@"a"])];
    [realm commitWriteTransaction];

    NSExpression *alpha = [NSExpression expressionForConstantValue:@"A"];

    NSUInteger (^count)(NSPredicateOperatorType, NSComparisonPredicateOptions) =
    ^(NSPredicateOperatorType type, NSComparisonPredicateOptions options) {
        NSPredicate * pred = [RLMPredicateUtil comparisonWithKeyPath: @"stringCol"
                                                          expression: alpha
                                                        operatorType: type
                                                             options: options];
        return [StringObject objectsWithPredicate: pred].count;
    };

    XCTAssertEqual(count(NSBeginsWithPredicateOperatorType, 0),
                   (NSUInteger)0, @"Case-sensitive BEGINSWITH operator in string comparison.");
    XCTAssertEqual(count(NSBeginsWithPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)1, @"Case-insensitive BEGINSWITH operator in string comparison.");

    XCTAssertEqual(count(NSEndsWithPredicateOperatorType, 0),
                   (NSUInteger)0, @"Case-sensitive ENDSWITH operator in string comparison.");
    XCTAssertEqual(count(NSEndsWithPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)1, @"Case-insensitive ENDSWITH operator in string comparison.");

    XCTAssertEqual(count(NSContainsPredicateOperatorType, 0),
                   (NSUInteger)0, @"Case-sensitive CONTAINS operator in string comparison.");
    XCTAssertEqual(count(NSContainsPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)1, @"Case-insensitive CONTAINS operator in string comparison.");

    XCTAssertEqual(count(NSEqualToPredicateOperatorType, 0),
                   (NSUInteger)0, @"Case-sensitive = or == operator in string comparison.");
    XCTAssertEqual(count(NSEqualToPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)1, @"Case-insensitive = or == operator in string comparison.");

    XCTAssertEqual(count(NSNotEqualToPredicateOperatorType, 0),
                   (NSUInteger)1, @"Case-sensitive != or <> operator in string comparison.");
    XCTAssertEqual(count(NSNotEqualToPredicateOperatorType, NSCaseInsensitivePredicateOption),
                   (NSUInteger)0, @"Case-insensitive != or <> operator in string comparison.");

    // Unsupported (but valid) modifiers.
    XCTAssertThrowsSpecificNamed(count(NSBeginsWithPredicateOperatorType,
                                       NSDiacriticInsensitivePredicateOption), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid predicate option",
                                 @"Diachritic insensitivity is not supported.");

    // Unsupported (but valid) operators.
    XCTAssertThrowsSpecificNamed(count(NSLikePredicateOperatorType, 0), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"LIKE not supported for string comparison.");
    XCTAssertThrowsSpecificNamed(count(NSMatchesPredicateOperatorType, 0), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"MATCHES not supported in string comparison.");

    // Invalid operators.
    XCTAssertThrowsSpecificNamed(count(NSLessThanPredicateOperatorType, 0), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"Invalid operator in string comparison.");
}

- (void)testBinaryComparisonInPredicate
{
    NSExpression *binary = [NSExpression expressionForConstantValue:[[NSData alloc] init]];

    NSUInteger (^count)(NSPredicateOperatorType) = ^(NSPredicateOperatorType type) {
        NSPredicate * pred = [RLMPredicateUtil comparisonWithKeyPath: @"binaryCol"
                                                          expression: binary
                                                        operatorType: type];
        return [BinaryObject objectsWithPredicate: pred].count;
    };

    XCTAssertEqual(count(NSBeginsWithPredicateOperatorType), (NSUInteger)0,
                   @"BEGINSWITH operator in binary comparison.");
    XCTAssertEqual(count(NSEndsWithPredicateOperatorType), (NSUInteger)0,
                   @"ENDSWITH operator in binary comparison.");
    XCTAssertEqual(count(NSContainsPredicateOperatorType), (NSUInteger)0,
                   @"CONTAINS operator in binary comparison.");
    XCTAssertEqual(count(NSEqualToPredicateOperatorType), (NSUInteger)0,
                   @"= or == operator in binary comparison.");
    XCTAssertEqual(count(NSNotEqualToPredicateOperatorType), (NSUInteger)0,
                   @"!= or <> operator in binary comparison.");

    // Invalid operators.
    XCTAssertThrowsSpecificNamed(count(NSLessThanPredicateOperatorType), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid operator type",
                                 @"Invalid operator in binary comparison.");
}

- (void)testAndCompound
{
    NSExpression *exp = [NSExpression expressionForConstantValue:@0];
    NSPredicate *subpred = [RLMPredicateUtil comparisonWithKeyPath:@"intCol"
                                                        expression:exp
                                                      operatorType:NSEqualToPredicateOperatorType];

    NSString *exc_name = @"filterWithPredicate:orderedBy: - Invalid query";

    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[]];
    BOOL(^proposition)() = [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];

    XCTAssertThrowsSpecificNamed(proposition(), NSException, exc_name,
                                 @"Compound OR predicate with no subpredicates is invalid.");

    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[subpred]];
    proposition = [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];

    XCTAssert(proposition(), @"Compound OR predicate with one subpredicate.");

    predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[subpred,subpred]];
    proposition = [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];

    XCTAssert(proposition(), @"Compound OR predicate with two subpredicates.");
}

- (void)testOrCompound
{
    NSExpression *exp = [NSExpression expressionForConstantValue:@0];
    NSPredicate *subpred = [RLMPredicateUtil comparisonWithKeyPath:@"intCol"
                                                        expression:exp
                                                      operatorType:NSEqualToPredicateOperatorType];

    NSString *exc_name = @"filterWithPredicate:orderedBy: - Invalid query";

    NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[]];
    BOOL(^proposition)() = [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];

    XCTAssertThrowsSpecificNamed(proposition(), NSException, exc_name,
                                 @"Compound OR predicate with no subpredicates is invalid.");

    predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[subpred]];
    proposition = [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];

    XCTAssert(proposition(), @"Compound OR predicate with one subpredicate.");

    predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[subpred,subpred]];
    proposition = [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];

    XCTAssert(proposition(), @"Compound OR predicate with two subpredicates.");
}

- (void)testNotCompound
{
    NSExpression *exp = [NSExpression expressionForConstantValue:@0];
    NSPredicate *subpred = [RLMPredicateUtil comparisonWithKeyPath:@"intCol"
                                                        expression:exp
                                                      operatorType:NSEqualToPredicateOperatorType];

    NSPredicate *predicate = [NSCompoundPredicate notPredicateWithSubpredicate:subpred];
    BOOL(^proposition)() = [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];

    XCTAssert(proposition(), @"Compound OR predicate with two subpredicates.");
}

- (void)testInvalidArgument
{
    NSPredicate *predicate = (NSPredicate *)@42;
    BOOL(^proposition)() = [RLMPredicateUtil isEmptyIntColWithPredicate:predicate];

    XCTAssertThrowsSpecificNamed(proposition(), NSException,
                                 @"filterWithPredicate:orderedBy: - Invalid argument",
                                 @"Non compound or comparison predicate is invalid.");
}

- (void)testDataTypes
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSDate *timeZero = [NSDate dateWithTimeIntervalSince1970:0];

    AllTypesObject *c = [[AllTypesObject alloc] init];
    
    c.BoolCol   = NO;
    c.IntCol  = 54;
    c.FloatCol = 0.7f;
    c.DoubleCol = 0.8;
    c.StringCol = @"foo";
    c.BinaryCol = bin1;
    c.DateCol = timeZero;
    c.cBoolCol = false;
    c.longCol = 99;
    c.mixedCol = @"string";
    c.objectCol = [[StringObject alloc] init];
    c.objectCol.stringCol = @"c";
    
    [realm addObject:c];

    [AllTypesObject createInRealm:realm withObject:@[@YES, @506, @7.7f, @8.8, @"banach", bin2,
                                                     timeNow, @YES, @(-20), @2, NSNull.null]];
    [realm commitWriteTransaction];
    
    AllTypesObject* row1 = [AllTypesObject allObjects][0];
    AllTypesObject* row2 = [AllTypesObject allObjects][1];

    XCTAssertEqual(row1.boolCol, NO,                    @"row1.BoolCol");
    XCTAssertEqual(row2.boolCol, YES,                   @"row2.BoolCol");
    XCTAssertEqual(row1.intCol, 54,                     @"row1.IntCol");
    XCTAssertEqual(row2.intCol, 506,                    @"row2.IntCol");
    XCTAssertEqual(row1.floatCol, 0.7f,                 @"row1.FloatCol");
    XCTAssertEqual(row2.floatCol, 7.7f,                 @"row2.FloatCol");
    XCTAssertEqual(row1.doubleCol, 0.8,                 @"row1.DoubleCol");
    XCTAssertEqual(row2.doubleCol, 8.8,                 @"row2.DoubleCol");
    XCTAssertTrue([row1.stringCol isEqual:@"foo"],      @"row1.StringCol");
    XCTAssertTrue([row2.stringCol isEqual:@"banach"],   @"row2.StringCol");
    XCTAssertTrue([row1.binaryCol isEqual:bin1],        @"row1.BinaryCol");
    XCTAssertTrue([row2.binaryCol isEqual:bin2],        @"row2.BinaryCol");
    XCTAssertTrue(([row1.dateCol isEqual:timeZero]),    @"row1.DateCol");
    XCTAssertTrue(([row2.dateCol isEqual:timeNow]),     @"row2.DateCol");
    XCTAssertEqual(row1.cBoolCol, (bool)false,          @"row1.cBoolCol");
    XCTAssertEqual(row2.cBoolCol, (bool)true,           @"row2.cBoolCol");
    XCTAssertEqual(row1.longCol, 99L,                   @"row1.IntCol");
    XCTAssertEqual(row2.longCol, -20L,                  @"row2.IntCol");
    XCTAssertTrue([row1.objectCol.stringCol isEqual:@"c"], @"row1.objectCol");
    XCTAssertNil(row2.objectCol,                        @"row2.objectCol");

    XCTAssertTrue([row1.mixedCol isEqual:@"string"],    @"row1.mixedCol");
    XCTAssertEqualObjects(row2.mixedCol, @2,            @"row2.mixedCol");
}

#pragma mark - Default Property Values

- (void)testNoDefaultPropertyValues
{
    // Test alloc init does not crash for no defaultPropertyValues implementation
    XCTAssertNoThrow(([[EmployeeObject alloc] init]), @"Not implementing defaultPropertyValues should not crash");
}

- (void)testNoDefaultAdd
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // Test #1
    StringObject *stringObject = [[StringObject alloc] init];
    XCTAssertThrows(([realm addObject:stringObject]), @"Adding object with no values specified for NSObject properties should throw exception if NSObject property is nil");
    
    // Test #2
    stringObject.stringCol = @"";
    XCTAssertNoThrow(([realm addObject:stringObject]), @"Having values in all NSObject properties should not throw exception when being added to realm");
    
    // Test #3
//    FIXME: Test should pass
//    IntObject *intObj = [[IntObject alloc] init];
//    XCTAssertThrows(([realm addObject:intObj]), @"Adding object with no values specified for NSObject properties should throw exception if NSObject property is nil");
    
    [realm commitWriteTransaction];
}

- (void)testDefaultValues
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    const int inputInt = 98;
    const float inputFloat = 231.0f;
    const double inputDouble = 123732.9231;
    const BOOL inputBool = NO;
    NSDate * const inputDate = [NSDate dateWithTimeIntervalSince1970:454321];
    NSString * const inputString = @"Westeros";
    NSData * const inputData = [@"inputData" dataUsingEncoding:NSUTF8StringEncoding];
    id inputMixed = @"Tyrion";
    
    NSDictionary * const inputKeyPathsAndValues = @{@"intCol" : @(inputInt), @"floatCol" : @(inputFloat), @"doubleCol" : @(inputDouble), @"boolCol" : @(inputBool), @"dateCol" : inputDate, @"stringCol" : inputString, @"binaryCol" : inputData, @"mixedCol" : inputMixed};
    NSArray * const keyPaths = inputKeyPathsAndValues.allKeys;
    
    for (NSUInteger i = 0; i < keyPaths.count; i++) {
        NSString *keyToDefault = keyPaths[i];
        NSMutableDictionary *dict = [inputKeyPathsAndValues mutableCopy];
        [dict removeObjectForKey:keyToDefault];
        
        [DefaultObject createInRealm:realm withObject:dict];
    }
    
    [realm commitWriteTransaction];

    // Test allObject for DefaultObject
    NSDictionary * const defaultKeyPathsAndValues = [DefaultObject defaultPropertyValues];
    for (NSUInteger i = 0; i < keyPaths.count; i++) {
        NSString *keyToDefault = keyPaths[i];
        DefaultObject *object = [DefaultObject allObjects][i];
        
        for (NSUInteger j = 0; j < keyPaths.count; j++) {
            NSString *key = keyPaths[j];
            if ([key isEqualToString:keyToDefault]) {
                XCTAssertEqualObjects([object valueForKey:keyToDefault], defaultKeyPathsAndValues[keyToDefault], @"Value should match value in defaultPropertyValues method");
            }
            else {
                XCTAssertEqualObjects([object valueForKey:key], inputKeyPathsAndValues[key], @"Value should match value that object was initialized with");
            }
        }        
    }
}

#pragma mark - Ignored Properties

- (void)testIgnoredUnsupportedProperty
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    XCTAssertNoThrow([IgnoredURLObject new], @"Creating a new object with an (ignored) unsupported \
                                               property type should not throw");
}

- (void)testCanUseIgnoredProperty
{
    NSURL *url = [NSURL URLWithString:@"http://realm.io"];
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    IgnoredURLObject *obj = [IgnoredURLObject new];
    obj.name = @"Realm";
    obj.url = url;
    [realm addObject:obj];
    XCTAssertEqual(obj.url, url, @"ignored properties should still be assignable and gettable inside a write block");
    
    [realm commitWriteTransaction];
    
    XCTAssertEqual(obj.url, url, @"ignored properties should still be assignable and gettable outside a write block");
    
    IgnoredURLObject *obj2 = [[IgnoredURLObject objectsWithPredicate:nil] firstObject];
    XCTAssertNotNil(obj2, @"object with ignored property should still be stored and accessible through the realm");
    
    XCTAssertEqualObjects(obj2.name, obj.name, @"persisted property should be the same");
    XCTAssertNil(obj2.url, @"ignored property should be nil when getting from realm");
}

- (void)testCreateInRealmValidationForDictionary
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSDictionary * const dictValidAllTypes = @{@"boolCol" : @NO,
                                               @"intCol" : @54,
                                               @"floatCol" : @0.7f,
                                               @"doubleCol" : @0.8,
                                               @"stringCol" : @"foo",
                                               @"binaryCol" : bin1,
                                               @"dateCol" : timeNow,
                                               @"cBoolCol" : @NO,
                                               @"longCol" : @(99),
                                               @"mixedCol" : @"mixed",
                                               @"objectCol": NSNull.null};
    
    [realm beginWriteTransaction];
    
    // Test NSDictonary
    XCTAssertNoThrow(([AllTypesObject createInRealm:realm withObject:dictValidAllTypes]), @"Creating object with valid value types should not throw exception");
    
    for (NSString *keyToInvalidate in dictValidAllTypes.allKeys) {
        NSMutableDictionary *invalidInput = [dictValidAllTypes mutableCopy];
        id obj = @"invalid";
        if ([keyToInvalidate isEqualToString:@"stringCol"]) {
            obj = @1;
        }
        
        invalidInput[keyToInvalidate] = obj;
        
        // Ignoring test for mixedCol since only NSObjects can go in NSDictionary
        if (![keyToInvalidate isEqualToString:@"mixedCol"]) {
            XCTAssertThrows(([AllTypesObject createInRealm:realm withObject:invalidInput]), @"Creating object with invalid value types should throw exception");
        }
    }
    
    
    [realm commitWriteTransaction];
}

- (void)testCreateInRealmValidationForArray
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // add test/link object to realm
    [realm beginWriteTransaction];
    StringObject *to = [StringObject createInRealm:realm withObject:@[@"c"]];
    [realm commitWriteTransaction];
    
    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSDate *timeNow = [NSDate dateWithTimeIntervalSince1970:1000000];
    NSArray * const arrayValidAllTypes = @[@NO, @54, @0.7f, @0.8, @"foo", bin1, timeNow, @NO, @(99), @"mixed", to];
    
    [realm beginWriteTransaction];
    
    // Test NSArray
    XCTAssertNoThrow(([AllTypesObject createInRealm:realm withObject:arrayValidAllTypes]), @"Creating object with valid value types should not throw exception");
    
    const NSInteger stringColIndex = 4;
    const NSInteger mixedColIndex = 9;
    for (NSUInteger i = 0; i < arrayValidAllTypes.count; i++) {
        NSMutableArray *invalidInput = [arrayValidAllTypes mutableCopy];
        
        id obj = @"invalid";
        if (i == stringColIndex) {
            obj = @1;
        }
        
        invalidInput[i] = obj;
        
        // Ignoring test for mixedCol since only NSObjects can go in NSArray
        if (i != mixedColIndex) {
            XCTAssertThrows(([AllTypesObject createInRealm:realm withObject:invalidInput]), @"Creating object with invalid value types should throw exception");
        }
    }
    
    [realm commitWriteTransaction];
}

- (void)testCreateInRealmWithMissingValue
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // This exception only gets thrown when there is no default vaule and it is for an NSObject property
    XCTAssertThrows(([EmployeeObject createInRealm:realm withObject:@{@"age" : @27, @"hired" : @YES}]), @"Missing values in NSDictionary should throw default value exception");
    
    // This exception gets thrown when count of array does not match with object schema
    XCTAssertThrows(([EmployeeObject createInRealm:realm withObject:@[@27, @YES]]), @"Missing values in NSDictionary should throw default value exception");
    
    [realm commitWriteTransaction];
}

- (void)testObjectDescription
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    // Init object before adding to realm
    EmployeeObject *soInit = [[EmployeeObject alloc] init];
    soInit.name = @"Peter";
    soInit.age = 30;
    soInit.hired = YES;
    [realm addObject:soInit];
    
    // description asserts block
    void(^descriptionAsserts)(NSString *) = ^(NSString *description) {
        XCTAssertTrue([description rangeOfString:@"name"].location != NSNotFound, @"column names should be displayed when calling \"description\" on RLMObject subclasses");
        XCTAssertTrue([description rangeOfString:@"Peter"].location != NSNotFound, @"column values should be displayed when calling \"description\" on RLMObject subclasses");
        
        XCTAssertTrue([description rangeOfString:@"age"].location != NSNotFound, @"column names should be displayed when calling \"description\" on RLMObject subclasses");
        XCTAssertTrue([description rangeOfString:[@30 description]].location != NSNotFound, @"column values should be displayed when calling \"description\" on RLMObject subclasses");
        
        XCTAssertTrue([description rangeOfString:@"hired"].location != NSNotFound, @"column names should be displayed when calling \"description\" on RLMObject subclasses");
        XCTAssertTrue([description rangeOfString:[@YES description]].location != NSNotFound, @"column values should be displayed when calling \"description\" on RLMObject subclasses");
    };
    
    // Test description in write block
    descriptionAsserts(soInit.description);
    
    [realm commitWriteTransaction];
    
    // Test description in read block
    NSString *objDescription = [[[EmployeeObject objectsWithPredicate:nil] firstObject] description];
    descriptionAsserts(objDescription);
}

#pragma mark - Indexing Tests

- (void)testIndex
{
    RLMProperty *nameProperty = [[RLMRealm defaultRealm] schema][IndexedObject.className][@"name"];
    XCTAssertTrue(nameProperty.attributes & RLMPropertyAttributeIndexed, @"indexed property should have an index");
    
    RLMProperty *ageProperty = [[RLMRealm defaultRealm] schema][IndexedObject.className][@"age"];
    XCTAssertFalse(ageProperty.attributes & RLMPropertyAttributeIndexed, @"non-indexed property shouldn't have an index");
}

@end
