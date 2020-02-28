#ifndef RLMAppCredentials_Private_h
#define RLMAppCredentials_Private_h

#import "RLMAppCredentials.h"
#import "sync/app_credentials.hpp"

@interface RLMAppCredentials()

@property std::shared_ptr<realm::app::AppCredentials> appCredentials;

@end

#endif /* RLMAppCredentials_Private_h */
