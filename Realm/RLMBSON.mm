#import <Foundation/Foundation.h>
#import "util/bson/bson.hpp"
#import "RLMUtil.hpp"
#import "RLMDecimal128_Private.hpp"
#import "RLMObjectId_Private.hpp"
#import "RLMBSON_Private.hpp"
#import <sstream>

using namespace realm;
using namespace bson;

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
    CFNumberType numberType = CFNumberGetType((CFNumberRef)self);

    switch (numberType) {
        case kCFNumberCharType:
            return RLMBSONTypeBool;
        case kCFNumberShortType:
        case kCFNumberCFIndexType:
        case kCFNumberNSIntegerType:
        case kCFNumberIntType:
        case kCFNumberSInt8Type:
        case kCFNumberSInt16Type:
        case kCFNumberSInt32Type:
            return RLMBSONTypeInt32;
        case kCFNumberLongType:
        case kCFNumberLongLongType:
        case kCFNumberSInt64Type:
            return RLMBSONTypeInt64;
        case kCFNumberCGFloatType:
        case kCFNumberFloatType:
        case kCFNumberDoubleType:
        case kCFNumberFloat32Type:
        case kCFNumberFloat64Type:
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
        for (auto it = bsonArray.begin(); it != bsonArray.end(); ++it) {
            [self addObject:BsonToRLMBSON(*it)];
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
        bsonArray.push_back(RLMBSONToBson(value));
    }
    return bsonArray;
}

- (RLMBSONType)bsonType {
    return RLMBSONTypeArray;
}

@end

#pragma mark NSDictionary

@implementation NSDictionary (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeDocument;
}

- (BsonDocument)bsonDocumentValue {
    BsonDocument bsonDocument;
    for (NSString *value in self) {
        bsonDocument[value.UTF8String] = RLMBSONToBson(self[value]);
    }
    return bsonDocument;
}

- (instancetype)initWithBsonDocument:(BsonDocument)bsonDocument {
    if ((self = [self init])) {
        for (auto it = bsonDocument.begin(); it != bsonDocument.end(); ++it) {
            auto entry = (*it);
            [self setValue:BsonToRLMBSON(entry.second) forKey:@(entry.first.data())];
        }

        return self;
    }

    return nil;
}

@end

#pragma mark NSData

@implementation NSData (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeBinary;
}

- (instancetype)initWithBsonBinary:(std::vector<char>)bsonBinary {
    if ((self = [self initWithBytes:bsonBinary.data() length:bsonBinary.size()])) {
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
    std::stringstream s;

    if ((_options & NSRegularExpressionCaseInsensitive) != 0) s << 'i';
    if ((_options & NSRegularExpressionUseUnixLineSeparators) != 0) s << 'm';
    if ((_options & NSRegularExpressionDotMatchesLineSeparators) != 0) s << 's';
    if ((_options & NSRegularExpressionUseUnicodeWordBoundaries) != 0) s << 'x';

    return RegularExpression(_pattern.UTF8String, s.str());
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
    }

    return nil;
}

@end

#pragma mark RLMMaxKey

@implementation RLMMaxKey

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if ([self class] == [other class]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
    return 0;
}

@end

#pragma mark RLMMaxKey

@implementation RLMMinKey

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if ([self class] == [other class]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
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

Bson RLMBSONToBson(id<RLMBSON> b) {
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
            return ((NSNumber *)b).boolValue;
        case RLMBSONTypeDouble:
            return ((NSNumber *)b).doubleValue;
        case RLMBSONTypeBinary:
            return (char**)((NSData *)b).bytes;
        case RLMBSONTypeTimestamp:
            return RLMTimestampForNSDate((NSDate *)b);
        case RLMBSONTypeDatetime:
            return Datetime(((NSDate *)b).timeIntervalSince1970);
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

id<RLMBSON> BsonToRLMBSON(Bson b) {
    switch (b.type()) {
        case realm::bson::Bson::Type::Null:
            return nil;
        case realm::bson::Bson::Type::Int32:
            return @(static_cast<int32_t>(b));
        case realm::bson::Bson::Type::Int64:
            return @(static_cast<int64_t>(b));
        case realm::bson::Bson::Type::Bool:
            return @(static_cast<bool>(b));
        case realm::bson::Bson::Type::Double:
            return @(static_cast<double>(b));
        case realm::bson::Bson::Type::String:
            return RLMStringDataToNSString(StringData(static_cast<std::string>(b).data()));
        case realm::bson::Bson::Type::Binary:
            return [[NSData alloc] initWithBsonBinary:static_cast<std::vector<char>>(b)];
        case realm::bson::Bson::Type::Timestamp:
            return RLMTimestampToNSDate(static_cast<Timestamp>(b));
        case realm::bson::Bson::Type::Datetime:
            return [[NSDate alloc] initWithTimeIntervalSince1970:static_cast<Datetime>(b).seconds_since_epoch];
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
            return [[NSDictionary alloc] initWithBsonDocument:static_cast<BsonDocument>(b)];
        case realm::bson::Bson::Type::Array:
            return [[NSMutableArray alloc] initWithBsonArray:static_cast<BsonArray>(b)];
    }
    return nil;
}
