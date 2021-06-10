////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMBSON_Private.hpp"
#import "RLMUUID_Private.hpp"

#import <realm/object-store/util/bson/bson.hpp>

#import <XCTest/XCTest.h>

using namespace realm::bson;

@interface RLMBSONTestCase : XCTestCase

@end

@implementation RLMBSONTestCase

- (void)testNilRoundTrip {
    auto bson = Bson();
    id<RLMBSON> rlm = RLMConvertBsonToRLMBSON(bson);
    XCTAssertEqual(rlm, [NSNull null]);
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testIntRoundTrip {
    auto bson = Bson(int64_t(42));
    NSNumber *rlm = (NSNumber *)RLMConvertBsonToRLMBSON(bson);
    XCTAssertEqual(rlm.intValue, 42);
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testBoolRoundTrip {
    auto bson = Bson(true);
    NSNumber *rlm = (NSNumber *)RLMConvertBsonToRLMBSON(bson);
    XCTAssertEqual(rlm.boolValue, true);
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testDoubleRoundTrip {
    auto bson = Bson(42.42);
    NSNumber *rlm = (NSNumber *)RLMConvertBsonToRLMBSON(bson);
    XCTAssertEqual(rlm.doubleValue, 42.42);
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testStringRoundTrip {
    auto bson = Bson("foo");
    NSString *rlm = (NSString *)RLMConvertBsonToRLMBSON(bson);
    XCTAssertEqualObjects(rlm, @"foo");
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testBinaryRoundTrip {
    auto bson = Bson(std::vector<char>{1, 2, 3});
    NSData *rlm = (NSData *)RLMConvertBsonToRLMBSON(bson);
    NSData *d = [[NSData alloc] initWithBytes:(char[]){1, 2, 3} length:3];
    XCTAssert([rlm isEqualToData: d]);
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testDatetimeMongoTimestampRoundTrip {
    auto bson = Bson(realm::Timestamp(42, 0));
    NSDate *rlm = (NSDate *)RLMConvertBsonToRLMBSON(bson);
    NSDate *d = [[NSDate alloc] initWithTimeIntervalSince1970:42];
    XCTAssert([rlm isEqualToDate: d]);
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testDatetimeTimestampRoundTrip {
    auto bson = Bson(realm::Timestamp(42, 0));
    NSDate *rlm = (NSDate *)RLMConvertBsonToRLMBSON(bson);
    NSDate *d = [[NSDate alloc] initWithTimeIntervalSince1970:42];
    XCTAssert([rlm isEqualToDate: d]);
    // Not an exact round trip since we ignore Timestamp Cocoa side
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), Bson(realm::Timestamp(42, 0)));
}

- (void)testObjectIdRoundTrip {
    auto bson = Bson(realm::ObjectId::gen());
    RLMObjectId *rlm = (RLMObjectId *)RLMConvertBsonToRLMBSON(bson);
    RLMObjectId *d = [[RLMObjectId alloc] initWithString:rlm.stringValue error:nil];
    XCTAssertEqualObjects(rlm, d);
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testUUIDRoundTrip {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"b1c11e54-e719-4275-b631-69ec3f2d616d"];
    auto bson = Bson(uuid.rlm_uuidValue);
    NSUUID *rlm = (NSUUID *)RLMConvertBsonToRLMBSON(bson);
    XCTAssertEqualObjects(rlm, uuid);
    XCTAssertEqual(RLMConvertRLMBSONToBson(rlm), bson);
}

- (void)testDocumentRoundTrip {
    NSDictionary<NSString *, id<RLMBSON>> *document = @{
        @"nil": [NSNull null],
        @"string": @"test string",
        @"true": @YES,
        @"false": @NO,
        @"int": @25,
        @"int32": @5,
        @"int64": @10,
        @"double": @15.0,
        @"decimal128": [[RLMDecimal128 alloc] initWithString:@"1.2E+10" error:nil],
        @"minkey": [RLMMinKey new],
        @"maxkey": [RLMMaxKey new],
        @"date": [[NSDate alloc] initWithTimeIntervalSince1970: 500],
        @"nestedarray": @[@[@1, @2], @[@3, @4]],
        @"nesteddoc": @{@"a": @1, @"b": @2, @"c": @NO, @"d": @[@3, @4], @"e" : @{@"f": @"g"}},
        @"oid": [[RLMObjectId alloc] initWithString:@"507f1f77bcf86cd799439011" error:nil],
        @"regex": [[NSRegularExpression alloc] initWithPattern:@"^abc" options:0 error:nil],
        @"array1": @[@1, @2],
        @"array2": @[@"string1", @"string2"],
        @"uuid": [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"],
    };
    
    auto bson = RLMConvertRLMBSONToBson(document);
    
    auto bsonDocument = static_cast<BsonDocument>(bson);

    XCTAssertEqual(document[@"nil"], [NSNull null]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["nil"]), document[@"nil"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["string"]), document[@"string"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["true"]), document[@"true"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["false"]), document[@"false"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["int"]), document[@"int"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["int32"]), document[@"int32"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["int64"]), document[@"int64"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["double"]), document[@"double"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["decimal128"]), document[@"decimal128"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["minkey"]), document[@"minkey"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["maxkey"]), document[@"maxkey"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["date"]), document[@"date"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["nestedarray"]), document[@"nestedarray"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["nesteddoc"]), document[@"nesteddoc"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["oid"]), document[@"oid"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["regex"]), document[@"regex"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["array1"]), document[@"array1"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["array2"]), document[@"array2"]);
    XCTAssertEqualObjects(RLMConvertBsonToRLMBSON(bsonDocument["uuid"]), document[@"uuid"]);
}

@end
