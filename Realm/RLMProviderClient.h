//
//  RLMProviderClient.h
//  Realm
//
//  Created by Lee Maguire on 24/03/2020.
//  Copyright © 2020 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "RLMApp.h"

NS_ASSUME_NONNULL_BEGIN

@class RLMApp;

@interface RLMProviderClient : NSObject

@property (nonatomic, weak) RLMApp *app;

- (instancetype)init:(RLMApp *)app;

@end

NS_ASSUME_NONNULL_END
