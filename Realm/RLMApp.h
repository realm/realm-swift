#import "RLMNetworkClient.h"

#ifndef RLMApp_h
#define RLMApp_h

@class RLMSyncUser, RLMAppCredentials;

/// A block type used for APIs which asynchronously vend an `RLMSyncUser`.
typedef void(^RLMUserCompletionBlock)(RLMSyncUser * _Nullable, NSError * _Nullable);

@interface RLMAppConfiguration : NSObject

@property NSString* _Nullable  baseURL;
@property (nonatomic, strong) id <RLMNetworkTransporting> _Nullable transport;

@end

@interface RLMApp : NSObject

+(_Nonnull instancetype) app:(NSString * _Nonnull) appId
               configuration:(RLMAppConfiguration * _Nullable)configuration;

-(void) loginWithCredential:(RLMAppCredentials * _Nonnull)credentials
          completionHandler:(RLMUserCompletionBlock _Nonnull)completionHandler;

@end
#endif /* RLMApp_h */
