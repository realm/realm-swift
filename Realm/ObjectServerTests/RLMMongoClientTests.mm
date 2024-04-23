////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncTestCase.h"
#import "RLMUser+ObjectServerTests.h"
#import "RLMWatchTestUtility.h"
#import "RLMBSON_Private.hpp"
#import "RLMUser_Private.hpp"

#import <realm/object-store/sync/app_user.hpp>
#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/util/bson/bson.hpp>

#import <sstream>

#if TARGET_OS_OSX

@interface RLMMongoClientTests : RLMSyncTestCase
@end

@implementation RLMMongoClientTests
- (NSArray *)defaultObjectTypes {
    return @[Dog.self];
}

- (void)tearDown {
    [self cleanupRemoteDocuments:[self.anonymousUser collectionForType:Dog.class app:self.app]];
    [super tearDown];
}

- (void)testFindOneAndModifyOptions {
    NSDictionary<NSString *, id<RLMBSON>> *projection = @{@"name": @1, @"breed": @1};
    NSArray<id<RLMBSON>> *sorting = @[@{@"age": @1}, @{@"coat": @1}];

    RLMFindOneAndModifyOptions *findOneAndModifyOptions1 = [[RLMFindOneAndModifyOptions alloc] init];
    XCTAssertNil(findOneAndModifyOptions1.projection);
    XCTAssertEqual(findOneAndModifyOptions1.sorting.count, 0U);
    XCTAssertFalse(findOneAndModifyOptions1.shouldReturnNewDocument);
    XCTAssertFalse(findOneAndModifyOptions1.upsert);

    RLMFindOneAndModifyOptions *findOneAndModifyOptions2 = [[RLMFindOneAndModifyOptions alloc] init];
    findOneAndModifyOptions2.projection = projection;
    findOneAndModifyOptions2.sorting = sorting;
    findOneAndModifyOptions2.shouldReturnNewDocument = YES;
    findOneAndModifyOptions2.upsert = YES;
    XCTAssertNotNil(findOneAndModifyOptions2.projection);
    XCTAssertEqual(findOneAndModifyOptions2.sorting.count, 2U);
    XCTAssertTrue(findOneAndModifyOptions2.shouldReturnNewDocument);
    XCTAssertTrue(findOneAndModifyOptions2.upsert);
    XCTAssertFalse([findOneAndModifyOptions2.projection isEqual:@{}]);
    XCTAssertTrue([findOneAndModifyOptions2.projection isEqual:projection]);
    XCTAssertFalse([findOneAndModifyOptions2.sorting isEqual:@{}]);
    XCTAssertTrue([findOneAndModifyOptions2.sorting isEqual:sorting]);

    RLMFindOneAndModifyOptions *findOneAndModifyOptions3 = [[RLMFindOneAndModifyOptions alloc]
                                                            initWithProjection:projection
                                                            sorting:sorting
                                                            upsert:YES
                                                            shouldReturnNewDocument:YES];
    XCTAssertNotNil(findOneAndModifyOptions3.projection);
    XCTAssertEqual(findOneAndModifyOptions3.sorting.count, 2U);
    XCTAssertTrue(findOneAndModifyOptions3.shouldReturnNewDocument);
    XCTAssertTrue(findOneAndModifyOptions3.upsert);
    XCTAssertFalse([findOneAndModifyOptions3.projection isEqual:@{}]);
    XCTAssertTrue([findOneAndModifyOptions3.projection isEqual:projection]);
    XCTAssertFalse([findOneAndModifyOptions3.sorting isEqual:@{}]);
    XCTAssertTrue([findOneAndModifyOptions3.sorting isEqual:sorting]);

    findOneAndModifyOptions3.projection = nil;
    findOneAndModifyOptions3.sorting = @[];
    XCTAssertNil(findOneAndModifyOptions3.projection);
    XCTAssertEqual(findOneAndModifyOptions3.sorting.count, 0U);
    XCTAssertTrue([findOneAndModifyOptions3.sorting isEqual:@[]]);

    RLMFindOneAndModifyOptions *findOneAndModifyOptions4 = [[RLMFindOneAndModifyOptions alloc]
                                                            initWithProjection:nil
                                                            sorting:@[]
                                                            upsert:NO
                                                            shouldReturnNewDocument:NO];
    XCTAssertNil(findOneAndModifyOptions4.projection);
    XCTAssertEqual(findOneAndModifyOptions4.sorting.count, 0U);
    XCTAssertFalse(findOneAndModifyOptions4.upsert);
    XCTAssertFalse(findOneAndModifyOptions4.shouldReturnNewDocument);
}

- (void)testFindOptions {
    NSDictionary<NSString *, id<RLMBSON>> *projection = @{@"name": @1, @"breed": @1};
    NSArray<id<RLMBSON>> *sorting = @[@{@"age": @1}, @{@"coat": @1}];

    RLMFindOptions *findOptions1 = [[RLMFindOptions alloc] init];
    XCTAssertNil(findOptions1.projection);
    XCTAssertEqual(findOptions1.sorting.count, 0U);
    XCTAssertEqual(findOptions1.limit, 0);

    findOptions1.limit = 37;
    findOptions1.projection = projection;
    findOptions1.sorting = sorting;
    XCTAssertEqual(findOptions1.limit, 37);
    XCTAssertTrue([findOptions1.projection isEqual:projection]);
    XCTAssertEqual(findOptions1.sorting.count, 2U);
    XCTAssertTrue([findOptions1.sorting isEqual:sorting]);

    RLMFindOptions *findOptions2 = [[RLMFindOptions alloc] initWithProjection:projection
                                                                      sorting:sorting];
    XCTAssertTrue([findOptions2.projection isEqual:projection]);
    XCTAssertEqual(findOptions2.sorting.count, 2U);
    XCTAssertEqual(findOptions2.limit, 0);
    XCTAssertTrue([findOptions2.sorting isEqual:sorting]);

    RLMFindOptions *findOptions3 = [[RLMFindOptions alloc] initWithLimit:37
                                                              projection:projection
                                                                 sorting:sorting];
    XCTAssertTrue([findOptions3.projection isEqual:projection]);
    XCTAssertEqual(findOptions3.sorting.count, 2U);
    XCTAssertEqual(findOptions3.limit, 37);
    XCTAssertTrue([findOptions3.sorting isEqual:sorting]);

    findOptions3.projection = nil;
    findOptions3.sorting = @[];
    XCTAssertNil(findOptions3.projection);
    XCTAssertEqual(findOptions3.sorting.count, 0U);

    RLMFindOptions *findOptions4 = [[RLMFindOptions alloc] initWithProjection:nil
                                                                      sorting:@[]];
    XCTAssertNil(findOptions4.projection);
    XCTAssertEqual(findOptions4.sorting.count, 0U);
    XCTAssertEqual(findOptions4.limit, 0);
}

- (void)testMongoInsert {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];

    XCTestExpectation *insertOneExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertOneDocument:@{@"name": @"fido", @"breed": @"cane corso"} completion:^(id<RLMBSON> objectId, NSError *error) {
        XCTAssertEqual(objectId.bsonType, RLMBSONTypeObjectId);
        XCTAssertNotEqualObjects(((RLMObjectId *)objectId).stringValue, @"");
        XCTAssertNil(error);
        [insertOneExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *insertManyExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertManyDocuments:@[
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"rex", @"breed": @"tibetan mastiff"}]
                         completion:^(NSArray<id<RLMBSON>> *objectIds, NSError *error) {
        XCTAssertGreaterThan(objectIds.count, 0U);
        XCTAssertNil(error);
        [insertManyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation = [self expectationWithDescription:@"should find documents"];
    RLMFindOptions *options = [[RLMFindOptions alloc] initWithLimit:0 projection:nil sorting:@[]];
    [collection findWhere:@{@"name": @"fido", @"breed": @"cane corso"}
                  options:options
               completion:^(NSArray<NSDictionary *> *documents, NSError *error) {
        XCTAssertEqual(documents.count, 3U);
        XCTAssertNil(error);
        [findExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoFind {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];

    XCTestExpectation *insertManyExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertManyDocuments:@[
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"rex", @"breed": @"tibetan mastiff"}]
                         completion:^(NSArray<id<RLMBSON>> *objectIds, NSError *error) {
        XCTAssertGreaterThan(objectIds.count, 0U);
        XCTAssertNil(error);
        [insertManyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation = [self expectationWithDescription:@"should find documents"];
    RLMFindOptions *options = [[RLMFindOptions alloc] initWithLimit:0 projection:nil sorting:@[]];
    [collection findWhere:@{@"name": @"fido", @"breed": @"cane corso"}
                  options:options
               completion:^(NSArray<NSDictionary *> *documents, NSError *error) {
        XCTAssertEqual(documents.count, 2U);
        XCTAssertNil(error);
        [findExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation2 = [self expectationWithDescription:@"should find documents"];
    [collection findWhere:@{@"name": @"fido", @"breed": @"cane corso"}
               completion:^(NSArray<NSDictionary *> *documents, NSError *error) {
        XCTAssertEqual(documents.count, 2U);
        XCTAssertNil(error);
        [findExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation3 = [self expectationWithDescription:@"should not find documents"];
    [collection findWhere:@{@"name": @"should not exist", @"breed": @"should not exist"}
               completion:^(NSArray<NSDictionary *> *documents, NSError *error) {
        XCTAssertEqual(documents.count, NSUInteger(0));
        XCTAssertNil(error);
        [findExpectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation4 = [self expectationWithDescription:@"should not find documents"];
    [collection findWhere:@{}
               completion:^(NSArray<NSDictionary *> *documents, NSError *error) {
        XCTAssertGreaterThan(documents.count, 0U);
        XCTAssertNil(error);
        [findExpectation4 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneExpectation1 = [self expectationWithDescription:@"should find documents"];
    [collection findOneDocumentWhere:@{@"name": @"fido", @"breed": @"cane corso"}
                          completion:^(NSDictionary *document, NSError *error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"fido"]);
        XCTAssertTrue([document[@"breed"] isEqualToString:@"cane corso"]);
        XCTAssertNil(error);
        [findOneExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneExpectation2 = [self expectationWithDescription:@"should find documents"];
    [collection findOneDocumentWhere:@{@"name": @"fido", @"breed": @"cane corso"}
                             options:options
                          completion:^(NSDictionary *document, NSError *error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"fido"]);
        XCTAssertTrue([document[@"breed"] isEqualToString:@"cane corso"]);
        XCTAssertNil(error);
        [findOneExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoAggregateAndCount {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];

    XCTestExpectation *insertManyExpectation = [self expectationWithDescription:@"should insert one document"];
    [collection insertManyDocuments:@[
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"rex", @"breed": @"tibetan mastiff"}]
                         completion:^(NSArray<id<RLMBSON>> *objectIds, NSError *error) {
        XCTAssertEqual(objectIds.count, 3U);
        XCTAssertNil(error);
        [insertManyExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *aggregateExpectation1 = [self expectationWithDescription:@"should aggregate documents"];
    [collection aggregateWithPipeline:@[@{@"name" : @"fido"}]
                           completion:^(NSArray<NSDictionary *> *documents, NSError *error) {
        RLMValidateErrorContains(error, RLMAppErrorDomain, RLMAppErrorMongoDBError,
                                 @"Unrecognized pipeline stage name: 'name'");
        XCTAssertNil(documents);
        [aggregateExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *aggregateExpectation2 = [self expectationWithDescription:@"should aggregate documents"];
    [collection aggregateWithPipeline:@[@{@"$match" : @{@"name" : @"fido"}}, @{@"$group" : @{@"_id" : @"$name"}}]
                           completion:^(NSArray<NSDictionary *> *documents, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNotNil(documents);
        XCTAssertGreaterThan(documents.count, 0U);
        [aggregateExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *countExpectation1 = [self expectationWithDescription:@"should aggregate documents"];
    [collection countWhere:@{@"name" : @"fido"}
                completion:^(NSInteger count, NSError *error) {
        XCTAssertGreaterThan(count, 0);
        XCTAssertNil(error);
        [countExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *countExpectation2 = [self expectationWithDescription:@"should aggregate documents"];
    [collection countWhere:@{@"name" : @"fido"}
                     limit:1
                completion:^(NSInteger count, NSError *error) {
        XCTAssertEqual(count, 1);
        XCTAssertNil(error);
        [countExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoUpdate {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];

    XCTestExpectation *updateExpectation1 = [self expectationWithDescription:@"should update document"];
    [collection updateOneDocumentWhere:@{@"name" : @"scrabby doo"}
                        updateDocument:@{@"name" : @"scooby"}
                                upsert:YES
                            completion:^(RLMUpdateResult *result, NSError *error) {
        XCTAssertNotNil(result);
        XCTAssertNotNil(result.documentId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)0);
        XCTAssertEqual(result.matchedCount, (NSUInteger)0);
        XCTAssertNil(error);
        [updateExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *updateExpectation2 = [self expectationWithDescription:@"should update document"];
    [collection updateOneDocumentWhere:@{@"name" : @"scooby"}
                        updateDocument:@{@"name" : @"fred"}
                                upsert:NO
                            completion:^(RLMUpdateResult *result, NSError *error) {
        XCTAssertNotNil(result);
        XCTAssertNil(result.documentId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)1);
        XCTAssertEqual(result.matchedCount, (NSUInteger)1);
        XCTAssertNil(error);
        [updateExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *updateExpectation3 = [self expectationWithDescription:@"should update document"];
    [collection updateOneDocumentWhere:@{@"name" : @"fred"}
                        updateDocument:@{@"name" : @"scrabby"}
                            completion:^(RLMUpdateResult *result, NSError *error) {
        XCTAssertNotNil(result);
        XCTAssertNil(result.documentId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)1);
        XCTAssertEqual(result.matchedCount, (NSUInteger)1);
        XCTAssertNil(error);
        [updateExpectation3 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *updateManyExpectation1 = [self expectationWithDescription:@"should update many documents"];
    [collection updateManyDocumentsWhere:@{@"name" : @"scrabby"}
                          updateDocument:@{@"name" : @"fred"}
                              completion:^(RLMUpdateResult *result, NSError *error) {
        XCTAssertNotNil(result);
        XCTAssertNil(result.documentId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)1);
        XCTAssertEqual(result.matchedCount, (NSUInteger)1);
        XCTAssertNil(error);
        [updateManyExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *updateManyExpectation2 = [self expectationWithDescription:@"should update many documents"];
    [collection updateManyDocumentsWhere:@{@"name" : @"john"}
                          updateDocument:@{@"name" : @"alex"}
                                  upsert:YES
                              completion:^(RLMUpdateResult *result, NSError *error) {
        XCTAssertNotNil(result);
        XCTAssertNotNil(result.documentId);
        XCTAssertEqual(result.modifiedCount, (NSUInteger)0);
        XCTAssertEqual(result.matchedCount, (NSUInteger)0);
        XCTAssertNil(error);
        [updateManyExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoFindAndModify {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];

    NSArray<id<RLMBSON>> *sorting = @[@{@"name": @1}, @{@"breed": @1}];
    RLMFindOneAndModifyOptions *findAndModifyOptions = [[RLMFindOneAndModifyOptions alloc]
                                                        initWithProjection:@{@"name" : @1, @"breed" : @1}
                                                        sorting:sorting
                                                        upsert:YES
                                                        shouldReturnNewDocument:YES];

    XCTestExpectation *findOneAndUpdateExpectation1 = [self expectationWithDescription:@"should find one document and update"];
    [collection findOneAndUpdateWhere:@{@"name" : @"alex"}
                       updateDocument:@{@"name" : @"max"}
                              options:findAndModifyOptions
                           completion:^(NSDictionary *document, NSError *error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"max"]);
        XCTAssertNil(error);
        [findOneAndUpdateExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndUpdateExpectation2 = [self expectationWithDescription:@"should find one document and update"];
    [collection findOneAndUpdateWhere:@{@"name" : @"max"}
                       updateDocument:@{@"name" : @"john"}
                           completion:^(NSDictionary *document, NSError *error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"max"]);
        XCTAssertNil(error);
        [findOneAndUpdateExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndReplaceExpectation1 = [self expectationWithDescription:@"should find one document and replace"];
    [collection findOneAndReplaceWhere:@{@"name" : @"alex"}
                   replacementDocument:@{@"name" : @"max"}
                               options:findAndModifyOptions
                            completion:^(NSDictionary *document, NSError *error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"max"]);
        XCTAssertNil(error);
        [findOneAndReplaceExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndReplaceExpectation2 = [self expectationWithDescription:@"should find one document and replace"];
    [collection findOneAndReplaceWhere:@{@"name" : @"max"}
                   replacementDocument:@{@"name" : @"john"}
                            completion:^(NSDictionary *document, NSError *error) {
        XCTAssertTrue([document[@"name"] isEqualToString:@"max"]);
        XCTAssertNil(error);
        [findOneAndReplaceExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

- (void)testMongoDelete {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];

    NSArray<RLMObjectId *> *objectIds = [self prepareDogDocumentsIn:collection];
    RLMObjectId *rexObjectId = objectIds[1];

    XCTestExpectation *deleteOneExpectation1 = [self expectationWithDescription:@"should delete first document in collection"];
    [collection deleteOneDocumentWhere:@{@"_id" : rexObjectId}
                            completion:^(NSInteger count, NSError *error) {
        XCTAssertEqual(count, 1);
        XCTAssertNil(error);
        [deleteOneExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findExpectation1 = [self expectationWithDescription:@"should find documents"];
    [collection findWhere:@{}
               completion:^(NSArray<NSDictionary *> *documents, NSError *error) {
        XCTAssertEqual(documents.count, 2U);
        XCTAssertTrue([documents[0][@"name"] isEqualToString:@"fido"]);
        XCTAssertNil(error);
        [findExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *deleteManyExpectation1 = [self expectationWithDescription:@"should delete many documents"];
    [collection deleteManyDocumentsWhere:@{@"name" : @"rex"}
                              completion:^(NSInteger count, NSError *error) {
        XCTAssertEqual(count, 0U);
        XCTAssertNil(error);
        [deleteManyExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *deleteManyExpectation2 = [self expectationWithDescription:@"should delete many documents"];
    [collection deleteManyDocumentsWhere:@{@"breed" : @"cane corso"}
                              completion:^(NSInteger count, NSError *error) {
        XCTAssertEqual(count, 1);
        XCTAssertNil(error);
        [deleteManyExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndDeleteExpectation1 = [self expectationWithDescription:@"should find one and delete"];
    [collection findOneAndDeleteWhere:@{@"name": @"john"}
                           completion:^(NSDictionary<NSString *, id<RLMBSON>> *document, NSError *error) {
        XCTAssertNotNil(document);
        NSString *name = (NSString *)document[@"name"];
        XCTAssertTrue([name isEqualToString:@"john"]);
        XCTAssertNil(error);
        [findOneAndDeleteExpectation1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];

    XCTestExpectation *findOneAndDeleteExpectation2 = [self expectationWithDescription:@"should find one and delete"];
    NSDictionary<NSString *, id<RLMBSON>> *projection = @{@"name": @1, @"breed": @1};
    NSArray<id<RLMBSON>> *sortDescriptors = @[@{@"_id": @1}, @{@"breed": @1}];
    RLMFindOneAndModifyOptions *findOneAndModifyOptions = [[RLMFindOneAndModifyOptions alloc]
                                                           initWithProjection:projection
                                                           sorting:sortDescriptors
                                                           upsert:YES
                                                           shouldReturnNewDocument:YES];

    [collection findOneAndDeleteWhere:@{@"name": @"john"}
                              options:findOneAndModifyOptions
                           completion:^(NSDictionary<NSString *, id<RLMBSON>> *document, NSError *error) {
        XCTAssertNil(document);
        // FIXME: when a projection is used, the server reports the error
        // "expected pre-image to match projection matcher" when there are no
        // matches, rather than simply doing nothing like when there is no projection
//        XCTAssertNil(error);
        (void)error;
        [findOneAndDeleteExpectation2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
}

#pragma mark - Watch

- (void)testWatch {
    [self performWatchTest:nil];
}

- (void)testWatchAsync {
    auto asyncQueue = dispatch_queue_create("io.realm.watchQueue", DISPATCH_QUEUE_CONCURRENT);
    [self performWatchTest:asyncQueue];
}

- (void)performWatchTest:(nullable dispatch_queue_t)delegateQueue {
    XCTestExpectation *expectation = [self expectationWithDescription:@"watch collection and receive change event 3 times"];

    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];

    RLMWatchTestUtility *testUtility =
        [[RLMWatchTestUtility alloc] initWithChangeEventCount:3
                                                  expectation:expectation];

    RLMChangeStream *changeStream = [collection watchWithDelegate:testUtility delegateQueue:delegateQueue];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WAIT_FOR_SEMAPHORE(testUtility.isOpenSemaphore, 30.0);
        for (int i = 0; i < 3; i++) {
            [collection insertOneDocument:@{@"name": @"fido"} completion:^(id<RLMBSON> objectId, NSError *error) {
                XCTAssertNil(error);
                XCTAssertNotNil(objectId);
            }];
            WAIT_FOR_SEMAPHORE(testUtility.semaphore, 30.0);
        }
        [changeStream close];
    });

    [self waitForExpectations:@[expectation] timeout:60.0];
}

- (void)testWatchWithMatchFilter {
    [self performWatchWithMatchFilterTest:nil];
}

- (void)testWatchWithMatchFilterAsync {
    auto asyncQueue = dispatch_queue_create("io.realm.watchQueue", DISPATCH_QUEUE_CONCURRENT);
    [self performWatchWithMatchFilterTest:asyncQueue];
}

- (NSArray<RLMObjectId *> *)prepareDogDocumentsIn:(RLMMongoCollection *)collection {
    __block NSArray<RLMObjectId *> *objectIds;
    XCTestExpectation *ex = [self expectationWithDescription:@"delete existing documents"];
    [collection deleteManyDocumentsWhere:@{} completion:^(NSInteger, NSError *error) {
        XCTAssertNil(error);
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:60.0];

    XCTestExpectation *insertManyExpectation = [self expectationWithDescription:@"should insert documents"];
    [collection insertManyDocuments:@[
        @{@"name": @"fido", @"breed": @"cane corso"},
        @{@"name": @"rex", @"breed": @"tibetan mastiff"},
        @{@"name": @"john", @"breed": @"tibetan mastiff"}]
                         completion:^(NSArray<id<RLMBSON>> *ids, NSError *error) {
        XCTAssertEqual(ids.count, 3U);
        for (id<RLMBSON> objectId in ids) {
            XCTAssertEqual(objectId.bsonType, RLMBSONTypeObjectId);
        }
        XCTAssertNil(error);
        objectIds = (NSArray *)ids;
        [insertManyExpectation fulfill];
    }];
    [self waitForExpectations:@[insertManyExpectation] timeout:60.0];
    return objectIds;
}

- (void)performWatchWithMatchFilterTest:(nullable dispatch_queue_t)delegateQueue {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];
    NSArray<RLMObjectId *> *objectIds = [self prepareDogDocumentsIn:collection];

    XCTestExpectation *expectation = [self expectationWithDescription:@"watch collection and receive change event 3 times"];

    RLMWatchTestUtility *testUtility =
        [[RLMWatchTestUtility alloc] initWithChangeEventCount:3
                                             matchingObjectId:objectIds[0]
                                                  expectation:expectation];

    RLMChangeStream *changeStream = [collection watchWithMatchFilter:@{@"fullDocument._id": objectIds[0]}
                                                            delegate:testUtility
                                                       delegateQueue:delegateQueue];

    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WAIT_FOR_SEMAPHORE(testUtility.isOpenSemaphore, 30.0);
        for (int i = 0; i < 3; i++) {
            [collection updateOneDocumentWhere:@{@"_id": objectIds[0]}
                                updateDocument:@{@"breed": @"king charles", @"name": [NSString stringWithFormat:@"fido-%d", i]}
                                    completion:^(RLMUpdateResult *, NSError *error) {
                XCTAssertNil(error);
            }];

            [collection updateOneDocumentWhere:@{@"_id": objectIds[1]}
                                updateDocument:@{@"breed": @"french bulldog", @"name": [NSString stringWithFormat:@"fido-%d", i]}
                                    completion:^(RLMUpdateResult *, NSError *error) {
                XCTAssertNil(error);
            }];
            WAIT_FOR_SEMAPHORE(testUtility.semaphore, 30.0);
        }
        [changeStream close];
    });
    [self waitForExpectations:@[expectation] timeout:60.0];
}

- (void)testWatchWithFilterIds {
    [self performWatchWithFilterIdsTest:nil];
}

- (void)testWatchWithFilterIdsAsync {
    auto asyncQueue = dispatch_queue_create("io.realm.watchQueue", DISPATCH_QUEUE_CONCURRENT);
    [self performWatchWithFilterIdsTest:asyncQueue];
}

- (void)performWatchWithFilterIdsTest:(nullable dispatch_queue_t)delegateQueue {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];
    NSArray<RLMObjectId *> *objectIds = [self prepareDogDocumentsIn:collection];

    XCTestExpectation *expectation = [self expectationWithDescription:@"watch collection and receive change event 3 times"];

    RLMWatchTestUtility *testUtility =
        [[RLMWatchTestUtility alloc] initWithChangeEventCount:3
                                             matchingObjectId:objectIds[0]
                                                  expectation:expectation];

    RLMChangeStream *changeStream = [collection watchWithFilterIds:@[objectIds[0]]
                                                          delegate:testUtility
                                                     delegateQueue:delegateQueue];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WAIT_FOR_SEMAPHORE(testUtility.isOpenSemaphore, 30.0);
        for (int i = 0; i < 3; i++) {
            [collection updateOneDocumentWhere:@{@"_id": objectIds[0]}
                                updateDocument:@{@"breed": @"king charles", @"name": [NSString stringWithFormat:@"fido-%d", i]}
                                    completion:^(RLMUpdateResult *, NSError *error) {
                XCTAssertNil(error);
            }];

            [collection updateOneDocumentWhere:@{@"_id": objectIds[1]}
                                updateDocument:@{@"breed": @"french bulldog", @"name": [NSString stringWithFormat:@"fido-%d", i]}
                                    completion:^(RLMUpdateResult *, NSError *error) {
                XCTAssertNil(error);
            }];
            WAIT_FOR_SEMAPHORE(testUtility.semaphore, 30.0);
        }
        [changeStream close];
    });

    [self waitForExpectations:@[expectation] timeout:60.0];
}

- (void)testMultipleWatchStreams {
    auto asyncQueue = dispatch_queue_create("io.realm.watchQueue", DISPATCH_QUEUE_CONCURRENT);
    [self performMultipleWatchStreamsTest:asyncQueue];
}

- (void)testMultipleWatchStreamsAsync {
    [self performMultipleWatchStreamsTest:nil];
}

- (void)performMultipleWatchStreamsTest:(nullable dispatch_queue_t)delegateQueue {
    RLMMongoCollection *collection = [self.anonymousUser collectionForType:Dog.class app:self.app];
    NSArray<RLMObjectId *> *objectIds = [self prepareDogDocumentsIn:collection];

    XCTestExpectation *expectation = [self expectationWithDescription:@"watch collection and receive change event 3 times"];
    expectation.expectedFulfillmentCount = 2;

    RLMWatchTestUtility *testUtility1 =
        [[RLMWatchTestUtility alloc] initWithChangeEventCount:3
                                             matchingObjectId:objectIds[0]
                                                  expectation:expectation];

    RLMWatchTestUtility *testUtility2 =
        [[RLMWatchTestUtility alloc] initWithChangeEventCount:3
                                             matchingObjectId:objectIds[1]
                                                  expectation:expectation];

    RLMChangeStream *changeStream1 = [collection watchWithFilterIds:@[objectIds[0]]
                                                           delegate:testUtility1
                                                      delegateQueue:delegateQueue];

    RLMChangeStream *changeStream2 = [collection watchWithFilterIds:@[objectIds[1]]
                                                           delegate:testUtility2
                                                      delegateQueue:delegateQueue];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WAIT_FOR_SEMAPHORE(testUtility1.isOpenSemaphore, 30.0);
        WAIT_FOR_SEMAPHORE(testUtility2.isOpenSemaphore, 30.0);
        for (int i = 0; i < 3; i++) {
            [collection updateOneDocumentWhere:@{@"_id": objectIds[0]}
                                updateDocument:@{@"breed": @"king charles", @"name": [NSString stringWithFormat:@"fido-%d", i]}
                                    completion:^(RLMUpdateResult *, NSError *error) {
                XCTAssertNil(error);
            }];

            [collection updateOneDocumentWhere:@{@"_id": objectIds[1]}
                                updateDocument:@{@"breed": @"french bulldog", @"name": [NSString stringWithFormat:@"fido-%d", i]}
                                    completion:^(RLMUpdateResult *, NSError *error) {
                XCTAssertNil(error);
            }];

            [collection updateOneDocumentWhere:@{@"_id": objectIds[2]}
                                updateDocument:@{@"breed": @"german shepard", @"name": [NSString stringWithFormat:@"fido-%d", i]}
                                    completion:^(RLMUpdateResult *, NSError *error) {
                XCTAssertNil(error);
            }];
            WAIT_FOR_SEMAPHORE(testUtility1.semaphore, 30.0);
            WAIT_FOR_SEMAPHORE(testUtility2.semaphore, 30.0);
        }
        [changeStream1 close];
        [changeStream2 close];
    });

    [self waitForExpectations:@[expectation] timeout:60.0];
}

#pragma mark - File paths

static NSString *newPathForPartitionValue(RLMUser *user, id<RLMBSON> partitionValue) {
    std::stringstream s;
    s << RLMConvertRLMBSONToBson(partitionValue);
    // Intentionally not passing the correct partition value here as we (accidentally?)
    // don't use the filename generated from the partition value
    realm::SyncConfig config(user.user, "null");
    return @(user.user->path_for_realm(config, s.str()).c_str());
}

- (void)testSyncFilePaths {
    RLMUser *user = self.anonymousUser;
    auto configuration = [user configurationWithPartitionValue:@"abc"];
    XCTAssertTrue([configuration.fileURL.path
                   hasSuffix:([NSString stringWithFormat:@"mongodb-realm/%@/%@/%%22abc%%22.realm",
                               self.appId, user.identifier])]);
    configuration = [user configurationWithPartitionValue:@123];
    XCTAssertTrue([configuration.fileURL.path
                   hasSuffix:([NSString stringWithFormat:@"mongodb-realm/%@/%@/%@.realm",
                               self.appId, user.identifier, @"%7B%22%24numberInt%22%3A%22123%22%7D"])]);
    configuration = [user configurationWithPartitionValue:nil];
    XCTAssertTrue([configuration.fileURL.path
                   hasSuffix:([NSString stringWithFormat:@"mongodb-realm/%@/%@/null.realm",
                               self.appId, user.identifier])]);

    XCTAssertEqualObjects([user configurationWithPartitionValue:@"abc"].fileURL.path,
                          newPathForPartitionValue(user, @"abc"));
    XCTAssertEqualObjects([user configurationWithPartitionValue:@123].fileURL.path,
                          newPathForPartitionValue(user, @123));
    XCTAssertEqualObjects([user configurationWithPartitionValue:nil].fileURL.path,
                          newPathForPartitionValue(user, nil));
}

static NSString *oldPathForPartitionValue(RLMUser *user, NSString *oldName) {
    realm::SyncConfig config(user.user, "null");
    return [NSString stringWithFormat:@"%@/%s%@.realm",
            [@(user.user->path_for_realm(config).c_str()) stringByDeletingLastPathComponent],
            user.user->user_id().c_str(), oldName];
}

- (void)testLegacyFilePathsAreUsedIfFilesArePresent {
    RLMUser *user = self.anonymousUser;

    auto testPartitionValue = [&](id<RLMBSON> partitionValue, NSString *oldName) {
        NSURL *url = [NSURL fileURLWithPath:oldPathForPartitionValue(user, oldName)];
        @autoreleasepool {
            auto configuration = [user configurationWithPartitionValue:partitionValue];
            configuration.fileURL = url;
            configuration.objectClasses = @[Person.class];
            RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
            [realm beginWriteTransaction];
            [Person createInRealm:realm withValue:[Person george]];
            [realm commitWriteTransaction];
        }

        auto configuration = [user configurationWithPartitionValue:partitionValue];
        configuration.objectClasses = @[Person.class];
        XCTAssertEqualObjects(configuration.fileURL, url);
        RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
        XCTAssertEqual([Person allObjectsInRealm:realm].count, 1U);
    };

    testPartitionValue(@"abc", @"%2F%2522abc%2522");
    testPartitionValue(@123, @"%2F%257B%2522%24numberInt%2522%253A%2522123%2522%257D");
    testPartitionValue(nil, @"%2Fnull");
}
@end

#endif // TARGET_OS_OSX
