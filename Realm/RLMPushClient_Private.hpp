//
//  RLMPushClient_Private.hpp
//  Realm
//
//  Created by mdb on 6/3/20.
//  Copyright © 2020 Realm. All rights reserved.
//

#import "RLMPushClient.h"

namespace realm {
namespace app {
class PushClient;
}
}

@interface RLMPushClient ()

- (instancetype)initWithPushClient:(realm::app::PushClient)pushClient;
- (realm::app::PushClient*)_pushClient;

@end
