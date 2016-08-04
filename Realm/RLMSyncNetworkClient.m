////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMSyncNetworkClient.h"

#import "RLMRealmConfiguration.h"
#import "RLMSyncPrivateUtil.h"

typedef void(^RLMSyncURLSessionCompletionBlock)(NSData *, NSURLResponse *, NSError *);

static NSUInteger const kHTTPCodeRange = 100;

typedef enum : NSUInteger {
    Informational       = 1, // 1XX
    Success             = 2, // 2XX
    Redirection         = 3, // 3XX
    ClientError         = 4, // 4XX
    ServerError         = 5, // 5XX
} RLMSyncHTTPErrorCodeType;

static NSRange RLM_rangeForErrorType(RLMSyncHTTPErrorCodeType type) {
    return NSMakeRange(type*100, kHTTPCodeRange);
}

@implementation RLMSyncNetworkClient

+ (NSURLSession *)session {
    return [NSURLSession sharedSession];
}

+ (NSURL *)urlForServer:(NSURL *)serverURL endpoint:(RLMSyncServerEndpoint)endpoint {
    NSString *pathComponent = nil;
    switch (endpoint) {
        case RLMSyncServerEndpointAuth:
            pathComponent = @"auth";
            break;
        case RLMSyncServerEndpointLogout:
            // TODO: fix this
            pathComponent = @"logout";
            NSAssert(NO, @"logout endpoint isn't implemented yet, don't use it");
            break;
        case RLMSyncServerEndpointAddCredential:
            // TODO: fix this
            pathComponent = @"addCredential";
            NSAssert(NO, @"add credential endpoint isn't implemented yet, don't use it");
            break;
        case RLMSyncServerEndpointRemoveCredential:
            // TODO: fix this
            pathComponent = @"removeCredential";
            NSAssert(NO, @"remove credential endpoint isn't implemented yet, don't use it");
            break;
    }
    NSAssert(pathComponent != nil, @"Unrecognized value for RLmSyncServerEndpoint enum");
    return [serverURL URLByAppendingPathComponent:pathComponent];
}

// FIXME: should completion argument also pass back the NSURLResponse and/or the raw data?
+ (void)postSyncRequestToEndpoint:(RLMSyncServerEndpoint)endpoint
                           server:(NSURL *)serverURL
                             JSON:(NSDictionary *)jsonDictionary
                       completion:(RLMSyncCompletionBlock)completionBlock {

    NSError *localError = nil;

    // Attempt to convert the JSON
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&localError];
    if (!jsonData) {
        completionBlock(localError, nil);
        return;
    }

    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self urlForServer:serverURL endpoint:endpoint]];
    request.HTTPBody = jsonData;
    request.HTTPMethod = @"POST";
    [request addValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    RLMSyncURLSessionCompletionBlock handler = ^(NSData *data,
                                                 NSURLResponse *response,
                                                 NSError *error) {
        NSError *localError = nil;

        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *actualResponse = (NSHTTPURLResponse *)response;
            BOOL badResponse = (NSLocationInRange(actualResponse.statusCode, RLM_rangeForErrorType(ClientError))
                                || NSLocationInRange(actualResponse.statusCode, RLM_rangeForErrorType(ServerError)));
            if (badResponse) {
                // Client or server error
                localError = [NSError errorWithDomain:RLMSyncErrorDomain
                                                 code:RLMSyncErrorHTTPStatusCodeError
                                             userInfo:@{@"statusCode": @(actualResponse.statusCode)}];
                completionBlock(localError, nil);
                return;
            }
        }

        // Parse out the JSON
        if (data && !error) {
            id json = [NSJSONSerialization JSONObjectWithData:data
                                                      options:(NSJSONReadingOptions)0
                                                        error:&localError];
            if (!json || localError) {
                // JSON parsing error
                completionBlock(localError, nil);
            } else if (![json isKindOfClass:[NSDictionary class]]) {
                // JSON response malformed
                localError = [NSError errorWithDomain:RLMSyncErrorDomain
                                                 code:RLMSyncErrorBadResponse
                                             userInfo:@{kRLMSyncErrorJSONKey: json}];
                completionBlock(localError, nil);
            } else {
                // JSON parsed successfully
                completionBlock(nil, (NSDictionary *)json);
            }
        } else {
            // Network error
            completionBlock(error, nil);
        }
    };

    // Add the request to a task and start it
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:handler];
    [task resume];
}

@end
