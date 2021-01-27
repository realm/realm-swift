//
//  RLMDictionary.hpp
//  Realm
//
//  Created by Pavel Yakimenko on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

#ifndef RLMDictionary_hpp
#define RLMDictionary_hpp

#import <Foundation/Foundation.h>

namespace realm {
class Dictionary;
}

NS_ASSUME_NONNULL_BEGIN

/**
 * Key-value collection. Where the key is a string and value is one of the available Realm types.
 */
@interface RLMDictionary: NSObject // There will be a collection type

@end
NS_ASSUME_NONNULL_END

#endif /* RLMDictionary_hpp */
