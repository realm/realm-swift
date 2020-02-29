#ifndef RLMAppCredentials_Private_hpp
#define RLMAppCredentials_Private_hpp

#import "RLMAppCredentials.h"
#import "sync/app_credentials.hpp"

@interface RLMAppCredentials()

@property std::shared_ptr<realm::app::AppCredentials> appCredentials;

@end

#endif /* RLMAppCredentials_Private_h */
