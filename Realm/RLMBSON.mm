#import <Foundation/Foundation.h>
#import "util/bson/bson.hpp"
#import "RLMDecimal128_Private.hpp"
#import "RLMObjectId_Private.hpp"
#import "RLMBSON_Private.hpp"

using namespace realm;
using namespace bson;

@implementation RLMObjectId (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeObjectId;
}

@end

@implementation NSData (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeInt32;
}

@end

@implementation NSString (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeString;
}

- (Bson)box {
    return Bson([self UTF8String]);
}

@end

@implementation NSNumber (RLMBSON)

- (RLMBSONType)bsonType {
    return RLMBSONTypeInt32;
}

- (Bson)box {

    CFNumberType numberType = CFNumberGetType((CFNumberRef)self);

    switch (numberType) {
        case
        kCFNumberShortType:
        kCFNumberCFIndexType:
        kCFNumberNSIntegerType:
        kCFNumberIntType:
        kCFNumberSInt8Type:
        kCFNumberSInt16Type:
        kCFNumberSInt32Type:
            return Bson([self intValue]);
        kCFNumberLongType:
        kCFNumberLongLongType:
        kCFNumberSInt64Type:
        kCFNumberMaxType:
            return Bson([self longLongValue]);
        kCFNumberCGFloatType:
        kCFNumberFloatType:
        kCFNumberDoubleType:
        kCFNumberFloat32Type:
        kCFNumberFloat64Type:
            return Bson([self doubleValue]);
        kCFNumberCharType:
            return Bson([self stringValue].UTF8String);
            break;
        default:
            // FIXME
            @throw [[NSError alloc] init];
            break;
    }
}

Bson RLMBSONToBson(id<RLMBSON> b) {
    switch ([b bsonType]) {
        case RLMBSONTypeString:
            return Bson(((NSString *)b).UTF8String);
        case RLMBSONTypeInt32:
            return Bson(((NSNumber *)b).intValue);
        case RLMBSONTypeInt64:
            return Bson(((NSNumber *)b).longLongValue);
        case RLMBSONTypeObjectId:
            return Bson([((RLMObjectId *)b) value]);
        default:
            // TODO: Add remaining types
            return util::none;
    }
}

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
            return @(static_cast<std::string>(b).data());
        case realm::bson::Bson::Type::ObjectId:
            return [[RLMObjectId alloc] initWithValue:static_cast<ObjectId>(b)];
        default:
            // TODO: Add remaining types
            return nil;
    }
    return nil;
}

@end
