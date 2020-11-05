//
//  Header.h
//  
//
//  Created by Pavel Yakimenko on 02/11/2020.
//

#ifndef Header_h
#define Header_h

#import <Realm/RLMObject.h>
#import "RLMProperty.h"
#include <realm/object-store/util/bson/bson.hpp>

namespace realm {
class UUID;
}

NS_ASSUME_NONNULL_BEGIN

@interface NSUUID(RLMUUIDSupport) <RLMUUID>

- (instancetype)initWithRealmUUID:(realm::UUID)uuidValue;

- (realm::UUID)uuidValue;

@end
NS_ASSUME_NONNULL_END

#endif /* Header_h */
