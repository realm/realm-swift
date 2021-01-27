//
//  RLMDictionary.h
//  Realm
//
//  Created by Pavel Yakimenko on 27/01/2021.
//  Copyright © 2021 Realm. All rights reserved.
//

#ifndef RLMDictionary_h
#define RLMDictionary_h

#import <Foundation/Foundation.h>
#import <Realm/RLMCollection.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Key-value collection. Where the key is a string and value is one of the available Realm types.
 */
@interface RLMDictionary<RLMObjectType>: NSObject<RLMCollection>

@end
NS_ASSUME_NONNULL_END

#endif /* RLMDictionary_h */
