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

#import "RLMNetworkClient.h"

#import "RLMRealmConfiguration.h"
#import "RLMSyncErrorResponseModel.h"
#import "RLMSyncUtil_Private.hpp"

typedef void(^RLMServerURLSessionCompletionBlock)(NSData *, NSURLResponse *, NSError *);

static NSUInteger const kHTTPCodeRange = 100;

typedef enum : NSUInteger {
    Informational       = 1, // 1XX
    Success             = 2, // 2XX
    Redirection         = 3, // 3XX
    ClientError         = 4, // 4XX
    ServerError         = 5, // 5XX
} RLMServerHTTPErrorCodeType;

static NSRange RLM_rangeForErrorType(RLMServerHTTPErrorCodeType type) {
    return NSMakeRange(type*100, kHTTPCodeRange);
}

@implementation RLMNetworkClient

+ (NSURLSession *)session {
    return [NSURLSession sharedSession];
}

+ (NSURL *)urlForServer:(NSURL *)serverURL endpoint:(RLMServerEndpoint)endpoint {
    NSString *pathComponent = nil;
    switch (endpoint) {
        case RLMServerEndpointAuth:
            pathComponent = @"auth";
            break;
        case RLMServerEndpointLogout:
            // TODO: fix this
            pathComponent = @"logout";
            NSAssert(NO, @"logout endpoint isn't implemented yet, don't use it");
            break;
        case RLMServerEndpointAddCredentials:
            // TODO: fix this
            pathComponent = @"addCredentials";
            NSAssert(NO, @"add credentials endpoint isn't implemented yet, don't use it");
            break;
        case RLMServerEndpointRemoveCredentials:
            // TODO: fix this
            pathComponent = @"removeCredentials";
            NSAssert(NO, @"remove credentials endpoint isn't implemented yet, don't use it");
            break;
        case RLMServerEndpointChangePassword:
            pathComponent = @"auth/password";
            break;
    }
    NSAssert(pathComponent != nil, @"Unrecognized value for RLMServerEndpoint enum");
    return [serverURL URLByAppendingPathComponent:pathComponent];
}

+ (void)postRequestToEndpoint:(RLMServerEndpoint)endpoint
                       server:(NSURL *)serverURL
                         JSON:(NSDictionary *)jsonDictionary
                   completion:(RLMSyncCompletionBlock)completionBlock {
    static NSTimeInterval const defaultTimeout = 60;
    [self postRequestToEndpoint:endpoint
                         server:serverURL
                           JSON:jsonDictionary
                        timeout:defaultTimeout
                     completion:completionBlock];
}

+ (void)postRequestToEndpoint:(RLMServerEndpoint)endpoint
                       server:(NSURL *)serverURL
                         JSON:(NSDictionary *)jsonDictionary
                      timeout:(NSTimeInterval)timeout
                   completion:(RLMSyncCompletionBlock)completionBlock {
    [self sendRequestToEndpoint:endpoint
                     httpMethod:@"POST"
                         server:serverURL
                           JSON:jsonDictionary
                        timeout:timeout
                     completion:completionBlock];
}

// FIXME: should completion argument also pass back the NSURLResponse and/or the raw data?
+ (void)sendRequestToEndpoint:(RLMServerEndpoint)endpoint
                   httpMethod:(NSString *)httpMethod
                       server:(NSURL *)serverURL
                         JSON:(NSDictionary *)jsonDictionary
                      timeout:(NSTimeInterval)timeout
                   completion:(RLMSyncCompletionBlock)completionBlock {

    NSError *localError = nil;

    // Attempt to convert the JSON
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary
                                                       options:(NSJSONWritingOptions)0
                                                         error:&localError];
    if (!jsonData) {
        completionBlock(localError, nil);
        return;
    }

    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self urlForServer:serverURL endpoint:endpoint]];
    request.HTTPBody = jsonData;
    request.HTTPMethod = httpMethod;
    request.timeoutInterval = MAX(timeout, 10);
    [request addValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    RLMServerURLSessionCompletionBlock handler = ^(NSData *data,
                                                   NSURLResponse *response,
                                                   NSError *error) {
        if (error != nil) {
            // Network error
            completionBlock(error, nil);
            return;
        }

        NSError *localError = nil;

        if (![self validateResponse:response data:data error:&localError]) {
            // Response error
            completionBlock(localError, nil);
            return;
        }

        // Parse out the JSON
        id json = [NSJSONSerialization JSONObjectWithData:data
                                                  options:(NSJSONReadingOptions)0
                                                    error:&localError];
        if (!json || localError) {
            // JSON parsing error
            completionBlock(localError, nil);
        } else if (![json isKindOfClass:[NSDictionary class]]) {
            // JSON response malformed
            localError = make_auth_error_bad_response(json);
            completionBlock(localError, nil);
        } else {
            // JSON parsed successfully
            completionBlock(nil, (NSDictionary *)json);
        }
    };

    // Add the request to a task and start it
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:handler];
    [task resume];
}

+ (BOOL)validateResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError * __autoreleasing *)error {
    __autoreleasing NSError *localError = nil;
    if (!error) {
        error = &localError;
    }

    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        // FIXME: Provide error message
        *error = make_auth_error_bad_response();
        return NO;
    }

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    BOOL badResponse = (NSLocationInRange(httpResponse.statusCode, RLM_rangeForErrorType(ClientError))
                        || NSLocationInRange(httpResponse.statusCode, RLM_rangeForErrorType(ServerError)));
    if (badResponse) {
        if (RLMSyncErrorResponseModel *responseModel = [self responseModelFromData:data]) {
            switch (responseModel.code) {
                case RLMSyncAuthErrorInvalidCredential:
                case RLMSyncAuthErrorUserDoesNotExist:
                case RLMSyncAuthErrorUserAlreadyExists:
                    *error = make_auth_error(responseModel);
                    break;
                default:
                    // Right now we assume that any codes not described
                    // above are generic HTTP error codes.
                    *error = make_auth_error_http_status(responseModel.status);
                    break;
            }
        } else {
            *error = make_auth_error_http_status(httpResponse.statusCode);
        }

        return NO;
    }

    if (!data) {
        // FIXME: provide error message
        *error = make_auth_error_bad_response();
        return NO;
    }

    return YES;
}

+ (RLMSyncErrorResponseModel *)responseModelFromData:(NSData *)data {
    if (data.length == 0) {
        return nil;
    }
    id json = [NSJSONSerialization JSONObjectWithData:data
                                              options:(NSJSONReadingOptions)0
                                                error:nil];
    if (!json || ![json isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [[RLMSyncErrorResponseModel alloc] initWithDictionary:json];
}

@end
