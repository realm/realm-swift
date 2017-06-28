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
#import "RLMUtil.hpp"

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

@interface RLMSyncServerEndpoint ()
- (instancetype)initPrivate NS_DESIGNATED_INITIALIZER;

/// The HTTP method the endpoint expects. Defaults to POST.
- (NSString *)httpMethod;

/// The URL to which the request should be made. Must be implemented.
- (NSURL *)urlForAuthServer:(NSURL *)authServerURL payload:(NSDictionary *)json;

/// The body for the request, if any.
- (NSData *)httpBodyForPayload:(NSDictionary *)json error:(NSError **)error;

/// The HTTP headers to be added to the request, if any.
- (NSDictionary<NSString *, NSString *> *)httpHeadersForPayload:(NSDictionary *)json;
@end

@implementation RLMSyncServerEndpoint

- (instancetype)initPrivate {
    return (self = [super init]);
}

- (NSString *)httpMethod {
    return @"POST";
}

- (NSURL *)urlForAuthServer:(__unused NSURL *)authServerURL payload:(__unused NSDictionary *)json {
    NSAssert(NO, @"This method must be overriden by concrete subclasses.");
    return nil;
}

- (NSData *)httpBodyForPayload:(NSDictionary *)json error:(NSError **)error {
    NSError *localError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                       options:(NSJSONWritingOptions)0
                                                         error:&localError];
    if (jsonData && !localError) {
        return jsonData;
    }
    NSAssert(localError, @"If there isn't a converted data object there must be an error.");
    if (error) {
        *error = localError;
    }
    return nil;
}

- (NSDictionary<NSString *, NSString *> *)httpHeadersForPayload:(__unused NSDictionary *)json {
    return @{@"Content-Type":   @"application/json;charset=utf-8",
             @"Accept":         @"application/json"};
}

@end

@implementation RLMSyncAuthEndpoint

+ (instancetype)endpoint {
    return [[RLMSyncAuthEndpoint alloc] initPrivate];
}

- (NSURL *)urlForAuthServer:(NSURL *)authServerURL payload:(__unused NSDictionary *)json {
    return [authServerURL URLByAppendingPathComponent:@"auth"];
}

@end

@implementation RLMSyncChangePasswordEndpoint

+ (instancetype)endpoint {
    return [[RLMSyncChangePasswordEndpoint alloc] initPrivate];
}

- (NSString *)httpMethod {
    return @"PUT";
}

- (NSURL *)urlForAuthServer:(NSURL *)authServerURL payload:(__unused NSDictionary *)json {
    return [authServerURL URLByAppendingPathComponent:@"auth/password"];
}

@end

@implementation RLMSyncGetUserInfoEndpoint

+ (instancetype)endpoint {
    return [[RLMSyncGetUserInfoEndpoint alloc] initPrivate];
}

- (NSString *)httpMethod {
    return @"GET";
}

- (NSURL *)urlForAuthServer:(NSURL *)authServerURL payload:(NSDictionary *)json {
    NSString *provider = json[kRLMSyncProviderKey];
    NSString *providerID = json[kRLMSyncProviderIDKey];
    NSAssert([provider isKindOfClass:[NSString class]] && [providerID isKindOfClass:[NSString class]],
             @"malformed request; this indicates a logic error in the binding.");
    NSCharacterSet *allowed = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *pathComponent = [NSString stringWithFormat:@"api/providers/%@/accounts/%@",
                               [provider stringByAddingPercentEncodingWithAllowedCharacters:allowed],
                               [providerID stringByAddingPercentEncodingWithAllowedCharacters:allowed]];
    return [authServerURL URLByAppendingPathComponent:pathComponent];
}

- (NSData *)httpBodyForPayload:(__unused NSDictionary *)json error:(__unused NSError **)error {
    return nil;
}

- (NSDictionary<NSString *, NSString *> *)httpHeadersForPayload:(NSDictionary *)json {
    NSString *authToken = [json objectForKey:kRLMSyncTokenKey];
    if (!authToken) {
        @throw RLMException(@"Malformed request; this indicates an internal error.");
    }
    return @{@"Authorization": authToken};
}

@end


@implementation RLMNetworkClient

+ (NSURLSession *)session {
    return [NSURLSession sharedSession];
}

+ (void)sendRequestToEndpoint:(RLMSyncServerEndpoint *)endpoint
                       server:(NSURL *)serverURL
                         JSON:(NSDictionary *)jsonDictionary
                   completion:(RLMSyncCompletionBlock)completionBlock {
    static NSTimeInterval const defaultTimeout = 60;
    [self sendRequestToEndpoint:endpoint
                         server:serverURL
                           JSON:jsonDictionary
                        timeout:defaultTimeout
                     completion:completionBlock];
}

+ (void)sendRequestToEndpoint:(RLMSyncServerEndpoint *)endpoint
                       server:(NSURL *)serverURL
                         JSON:(NSDictionary *)jsonDictionary
                      timeout:(NSTimeInterval)timeout
                   completion:(RLMSyncCompletionBlock)completionBlock {
    // Create the request
    NSError *localError = nil;
    NSURL *requestURL = [endpoint urlForAuthServer:serverURL payload:jsonDictionary];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    request.HTTPBody = [endpoint httpBodyForPayload:jsonDictionary error:&localError];
    if (localError) {
        completionBlock(localError, nil);
        return;
    }
    request.HTTPMethod = [endpoint httpMethod];
    request.timeoutInterval = MAX(timeout, 10);
    NSDictionary<NSString *, NSString *> *headers = [endpoint httpHeadersForPayload:jsonDictionary];
    for (NSString *key in headers) {
        [request addValue:headers[key] forHTTPHeaderField:key];
    }
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
