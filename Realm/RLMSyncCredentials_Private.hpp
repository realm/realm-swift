#ifndef RLMSyncCredentials_Private_h
#define RLMSyncCredentials_Private_h

#import "RLMSyncCredentials.h"
#import "app.hpp"

@interface RLMSyncCredentials ()

- (instancetype)initWithAppCredentials:(realm::AppCredentials *)appCredentials;

@property (nonatomic, readwrite) realm::AppCredentials *appCredentials;

@end

#endif /* RLMSyncCredentials_Private_h */
