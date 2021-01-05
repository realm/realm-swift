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

#import "RLMDecimal128_Private.hpp"
#import "RLMObjectId_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/util/bson/bson.hpp>

using namespace realm;
using namespace bson;

#pragma mark NSNull

@implementation NSNull (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeNull;
}

@end

#pragma mark RLMObjectId

@implementation RLMObjectId (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeObjectId;
}

@end

#pragma mark RLMDecimal128

@implementation RLMDecimal128 (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeDecimal128;
}

@end

#pragma mark NSString

@implementation NSString (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeString;
}

@end

#pragma mark NSNumber

@implementation NSNumber (RLMBSON)

- (RLMBSONType)bsonType {
    char numberType = [self objCType][0];
    
    if (numberType == *@encode(bool) ||
        numberType == *@encode(char)) {
        return RLMBSONTypeBool;
    } else if (numberType == *@encode(int) ||
               numberType == *@encode(short) ||
               numberType == *@encode(unsigned short) ||
               numberType == *@encode(unsigned int)) {
        return RLMBSONTypeInt32;
    } else if (numberType == *@encode(long) ||
               numberType == *@encode(long long) ||
               numberType == *@encode(unsigned long) ||
               numberType == *@encode(unsigned long long)) {
        return RLMBSONTypeInt64;
    } else {
        return RLMBSONTypeDouble;
    }
}

@end

#pragma mark NSMutableArray

@implementation NSMutableArray (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeArray;
}

- (instancetype)initWithBsonArray:(BsonArray)bsonArray {

    if ((self = [self init])) {
        for (auto& entry : bsonArray) {
            [self addObject:RLMConvertBsonToRLMBSON(entry)];
        }

        return self;
    }

    return nil;
}

@end

@implementation NSArray (RLMBSON)

- (BsonArray)bsonArrayValue {
    BsonArray bsonArray;
    for (id value in self) {
        bsonArray.push_back(RLMConvertRLMBSONToBson(value));
    }
    return bsonArray;
}

- (RLMBSONType)bsonType {
    return RLMBSONTypeArray;
}

@end

#pragma mark NSDictionary

@implementation NSMutableDictionary (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeDocument;
}

- (BsonDocument)bsonDocumentValue {
    BsonDocument bsonDocument;
    for (NSString *value in self) {
        bsonDocument[value.UTF8String] = RLMConvertRLMBSONToBson(self[value]);
    }
    return bsonDocument;
}

- (instancetype)initWithBsonDocument:(BsonDocument)bsonDocument {
    if ((self = [self init])) {
        for (auto it = bsonDocument.begin(); it != bsonDocument.end(); ++it) {
            const auto& entry = (*it);
            [self setObject:RLMConvertBsonToRLMBSON(entry.second) forKey:@(entry.first.data())];
        }

        return self;
    }

    return nil;
}

@end

@implementation NSDictionary (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeDocument;
}

- (BsonDocument)bsonDocumentValue {
    BsonDocument bsonDocument;
    for (NSString *value in self) {
        bsonDocument[value.UTF8String] = RLMConvertRLMBSONToBson(self[value]);
    }
    return bsonDocument;
}

@end

#pragma mark NSData

@implementation NSData (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeBinary;
}

- (instancetype)initWithBsonBinary:(std::vector<char>)bsonBinary {
    if ((self = [NSData dataWithBytes:bsonBinary.data() length:bsonBinary.size()])) {
        return self;
    }

    return nil;
}

@end

#pragma mark NSDate

@implementation NSDate (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeDatetime;
}

@end

#pragma mark NSRegularExpression

@implementation NSRegularExpression (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeRegularExpression;
}

- (RegularExpression)regularExpressionValue {
    using Option = RegularExpression::Option;
    std::string s;

    if ((_options & NSRegularExpressionCaseInsensitive) != 0) s += 'i';
    if ((_options & NSRegularExpressionUseUnixLineSeparators) != 0) s += 'm';
    if ((_options & NSRegularExpressionDotMatchesLineSeparators) != 0) s += 's';
    if ((_options & NSRegularExpressionUseUnicodeWordBoundaries) != 0) s += 'x';

    return RegularExpression(_pattern.UTF8String, s);
}

- (instancetype)initWithRegularExpression:(RegularExpression)regularExpression {
    if ((self = [self init])) {
        _pattern = @(regularExpression.pattern().data());
        switch (regularExpression.options()) {
            case realm::bson::RegularExpression::Option::None:
                _options = 0;
                break;
            case realm::bson::RegularExpression::Option::IgnoreCase:
                _options = NSRegularExpressionCaseInsensitive;
                break;
            case realm::bson::RegularExpression::Option::Multiline:
                _options = NSRegularExpressionUseUnixLineSeparators;
                break;
            case realm::bson::RegularExpression::Option::Dotall:
                _options = NSRegularExpressionDotMatchesLineSeparators;
                break;
            case realm::bson::RegularExpression::Option::Extended:
                _options = NSRegularExpressionUseUnicodeWordBoundaries;
                break;
        }
        return self;
    }

    return nil;
}

@end

#pragma mark RLMMaxKey

@implementation RLMMaxKey

- (BOOL)isEqual:(id)other {
    return other == self || ([other class] == [self class]);
}

- (NSUInteger)hash {
    return 0;
}

@end

#pragma mark RLMMaxKey

@implementation RLMMinKey

- (BOOL)isEqual:(id)other {
    return other == self || ([other class] == [self class]);
}

- (NSUInteger)hash {
    return 0;
}

@end

@implementation RLMMaxKey (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeMaxKey;
}

@end

@implementation RLMMinKey (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeMinKey;
}

@end

#pragma mark RLMBSONToBson

Bson RLMConvertRLMBSONToBson(id<RLMBSON> b) {
    switch ([b bsonType]) {
        case RLMBSONTypeString:
            return ((NSString *)b).UTF8String;
        case RLMBSONTypeInt32:
            return ((NSNumber *)b).intValue;
        case RLMBSONTypeInt64:
            return ((NSNumber *)b).longLongValue;
        case RLMBSONTypeObjectId:
            return [((RLMObjectId *)b) value];
        case RLMBSONTypeNull:
            return util::none;
        case RLMBSONTypeBool:
            return (bool)((NSNumber *)b).boolValue;
        case RLMBSONTypeDouble:
            return ((NSNumber *)b).doubleValue;
        case RLMBSONTypeBinary:
            return std::vector<char>((char*)((NSData *)b).bytes,
                                     ((char*)((NSData *)b).bytes) + (int)((NSData *)b).length);
        case RLMBSONTypeTimestamp:
            return RLMTimestampForNSDate((NSDate *)b);
        case RLMBSONTypeDatetime:
            return MongoTimestamp(((NSDate *)b).timeIntervalSince1970, 0);
        case RLMBSONTypeDecimal128:
            return [((RLMDecimal128 *)b) decimal128Value];
        case RLMBSONTypeRegularExpression:
            return [((NSRegularExpression *)b) regularExpressionValue];
        case RLMBSONTypeMaxKey:
            return max_key;
        case RLMBSONTypeMinKey:
            return min_key;
        case RLMBSONTypeDocument:
            return [((NSDictionary *)b) bsonDocumentValue];
        case RLMBSONTypeArray:
            return [((NSArray *)b) bsonArrayValue];
    }
}

#pragma mark BsonToRLMBSON

id<RLMBSON> RLMConvertBsonToRLMBSON(const Bson& b) {
    switch (b.type()) {
        case realm::bson::Bson::Type::Null:
            return [NSNull null];
        case realm::bson::Bson::Type::Int32:
            return @(static_cast<int32_t>(b));
        case realm::bson::Bson::Type::Int64:
            return @(static_cast<int64_t>(b));
        case realm::bson::Bson::Type::Bool:
            return @(static_cast<bool>(b));
        case realm::bson::Bson::Type::Double:
            return @(static_cast<double>(b));
        case realm::bson::Bson::Type::String:
            return RLMStringDataToNSString(static_cast<std::string>(b).c_str());
        case realm::bson::Bson::Type::Binary:
            return [[NSData alloc] initWithBsonBinary:static_cast<std::vector<char>>(b)];
        case realm::bson::Bson::Type::Timestamp:
            return [[NSDate alloc] initWithTimeIntervalSince1970:static_cast<MongoTimestamp>(b).seconds];
        case realm::bson::Bson::Type::Datetime:
            return [[NSDate alloc] initWithTimeIntervalSince1970:static_cast<Timestamp>(b).get_seconds()];
        case realm::bson::Bson::Type::ObjectId:
            return [[RLMObjectId alloc] initWithValue:static_cast<ObjectId>(b)];
        case realm::bson::Bson::Type::Decimal128:
            return [[RLMDecimal128 alloc] initWithDecimal128:static_cast<Decimal128>(b)];
        case realm::bson::Bson::Type::RegularExpression:
            return [[NSRegularExpression alloc] initWithRegularExpression:static_cast<RegularExpression>(b)];
        case realm::bson::Bson::Type::MaxKey:
            return [RLMMaxKey new];
        case realm::bson::Bson::Type::MinKey:
            return [RLMMinKey new];
        case realm::bson::Bson::Type::Document:
            return [[NSMutableDictionary alloc] initWithBsonDocument:static_cast<BsonDocument>(b)];
        case realm::bson::Bson::Type::Array:
            return [[NSMutableArray alloc] initWithBsonArray:static_cast<BsonArray>(b)];
        case realm::bson::Bson::Type::Uuid:
            REALM_COMPILER_HINT_UNREACHABLE();
    }
    return nil;
}

id<RLMBSON> RLMConvertBsonDocumentToRLMBSON(realm::util::Optional<BsonDocument> b) {
    return b ? RLMConvertBsonToRLMBSON(*b) : nil;
}
