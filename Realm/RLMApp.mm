#import "RLMApp.h"
#import "RLMJSONModels.h"
#import "RLMNetworkClient.h"
#import "RLMRealmConfiguration.h"
#import "RLMSyncCredentials.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncUser.h"
#import "RLMSyncUtil.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMSyncUser_Private.hpp"

#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

@implementation RLMFunctions {
    NSURL *_route;
}

- (instancetype) initWithRoute:(NSURL *)route {
    if (!(self = [super init]))
        return nil;

    _route = route;
    return self;
}

- (void)callFunction:(NSString *)name
           arguments:(NSArray *)arguments
             timeout:(NSTimeInterval)timeout
       callbackQueue:(dispatch_queue_t)callbackQueue
        onCompletion:(RLMFunctionCompletionBlock)completion {
    NSDictionary *json = @{
        @"name": name,
        @"arguments": arguments,
        @"token": RLMSyncUser.allUsers.allValues.lastObject.accessToken,
    };

    [RLMAppFunctionEndpoint sendRequestToServer:_route
                                           JSON:json
                                        timeout:timeout
                                     completion:^(NSError *error, NSData *data) {
        dispatch_async(callbackQueue, ^{
            completion(data, error);
        });
    }];
}

@end

@implementation RLMAuth {
    NSURL *_route;
}


- (instancetype) initWithRoute:(NSURL *)route {
    if (!(self = [super init]))
        return nil;

    _route = route;
    return self;
}

- (NSDictionary<NSString *, RLMSyncUser *>*)allUsers {
    NSArray *allUsers = [[RLMSyncManager sharedManager] _allUsers];
    return [NSDictionary dictionaryWithObjects:allUsers
                                       forKeys:[allUsers valueForKey:@"identity"]];
}

- (RLMSyncUser *)currentUser {
    return [[RLMSyncManager sharedManager] _currentUser];
}

- (void)logInWithCredentials:(RLMSyncCredentials *)credentials
                     timeout:(NSTimeInterval)timeout
               callbackQueue:(dispatch_queue_t)callbackQueue
                onCompletion:(RLMUserCompletionBlock)completion {
    // Prepare login network request
    NSMutableDictionary *json = [@{
        kRLMSyncProviderKey: credentials.provider
    } mutableCopy];


    if (credentials.userInfo.count) {
        // Munge user info into the JSON request.
        [json addEntriesFromDictionary:credentials.userInfo];
    }

    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (error) {
            return completion(nil, error);
        }

        RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithDictionary:json
                                                                    requireAccessToken:YES
                                                                   requireRefreshToken:YES];
        if (!model) {
            // Malformed JSON
            return completion(nil, make_auth_error_bad_response(json));
        }

        realm::SyncUserIdentifier identity{
            ((NSString *)json[@"user_id"]).UTF8String,
            _route.absoluteString.UTF8String
        };
        auto sync_user = realm::SyncManager::shared().get_user(identity ,
                                                               [model.refreshToken.token UTF8String],
                                                               [model.accessToken.token UTF8String]);
        if (!sync_user) {
            return completion(nil, make_auth_error_client_issue());
        }
        sync_user->set_is_admin(model.refreshToken.tokenData.isAdmin);
        return completion([[RLMSyncUser alloc] initWithSyncUser:std::move(sync_user)], nil);
    };

    [RLMSyncAuthEndpoint sendRequestToServer:_route
                                        JSON:json
                                     timeout:timeout
                                  completion:^(NSError *error, NSDictionary *dictionary) {
        dispatch_async(callbackQueue, ^{
            handler(error, dictionary);
        });
    }];
}

@end

@implementation RLMApp {
    NSString *_appID;
}

static NSString *defaultBaseURL = @"https://stitch.mongodb.com";
static NSString *baseRoute = @"/api/client/v2.0";
static NSMutableDictionary<NSString *, RLMApp *> *_allApps;

- (instancetype)initWithAppID:(NSString *)appID {
    if (!(self = [super init]))
        return nil;

    _appID = appID;

    NSString *appRoute = [[defaultBaseURL stringByAppendingString:baseRoute] stringByAppendingString:@"/app/%@"];

    _auth = [[RLMAuth alloc] initWithRoute:[[NSURL alloc] initWithString:
                                            [[NSString alloc] initWithFormat:[appRoute stringByAppendingString:@"/auth"],
                                             appID]]];

    _functions = [[RLMFunctions alloc] initWithRoute:[[NSURL alloc] initWithString: [[NSString alloc] initWithFormat:appRoute, appID]]];
    return self;
}

+ (NSDictionary<NSString *,RLMApp *> *)allApps {
    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        _allApps = [NSMutableDictionary new];
    });

    return _allApps;
}

+ (instancetype)app:(NSString *)appID {
    if (auto app = [RLMApp.allApps valueForKey:appID]) {
        return app;
    }

    RLMApp *app = [[RLMApp alloc] initWithAppID: appID];
    [((NSMutableDictionary *)RLMApp.allApps) setObject:app forKey:appID];
    return app;
}

- (RLMRealmConfiguration *)configuration {
    NSURL *url = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    url = [url URLByAppendingPathComponent:_appID];
    auto config = [[RLMRealmConfiguration alloc] init];
    config.fileURL = url;
    return config;
}
@end
