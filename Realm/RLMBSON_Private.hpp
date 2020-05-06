#ifndef RLMBSON_Private_h
#define RLMBSON_Private_h

#import <Foundation/Foundation.h>
#import "util/bson/bson.hpp"
#import "RLMDecimal128_Private.hpp"
#import "RLMBSON.h"
#import "RLMUtil.hpp"
#import "RLMObjectId_Private.hpp"
#import <realm/mixed.hpp>

using namespace realm;
using namespace bson;

Bson RLMBSONToBson(id<RLMBSON> b);
id<RLMBSON> BsonToRLMBSON(Bson b);



#endif /* RLMBSON_Private_h */
