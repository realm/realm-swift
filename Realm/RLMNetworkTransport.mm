////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMNetworkTransport.h"

#import "RLMApp.h"
#import "RLMJSONModels.h"
#import "RLMRealmConfiguration.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/util/scope_exit.hpp>

#import "sync/generic_network_transport.hpp"

using namespace realm;

typedef void(^RLMServerURLSessionCompletionBlock)(NSData *, NSURLResponse *, NSError *);

static_assert((int)RLMHTTPMethodGET        == (int)app::HttpMethod::get);
static_assert((int)RLMHTTPMethodPOST       == (int)app::HttpMethod::post);
static_assert((int)RLMHTTPMethodPUT        == (int)app::HttpMethod::put);
static_assert((int)RLMHTTPMethodPATCH      == (int)app::HttpMethod::patch);
static_assert((int)RLMHTTPMethodDELETE     == (int)app::HttpMethod::del);

#pragma mark RLMSessionDelegate

@interface RLMSessionDelegate <NSURLSessionDelegate> : NSObject
+ (instancetype)delegateWithCompletion:(RLMNetworkTransportCompletionBlock)completion;
@end

NSString * const RLMHTTPMethodToNSString[] = {
    [RLMHTTPMethodGET] = @"GET",
    [RLMHTTPMethodPOST] = @"POST",
    [RLMHTTPMethodPUT] = @"PUT",
    [RLMHTTPMethodPATCH] = @"PATCH",
    [RLMHTTPMethodDELETE] = @"DELETE"
};

@implementation RLMRequest
@end

@implementation RLMResponse
@end

@implementation RLMNetworkTransport

- (void)sendRequestToServer:(RLMRequest *) request
                 completion:(RLMNetworkTransportCompletionBlock)completionBlock; {
    // Create the request
    NSURL *requestURL = [[NSURL alloc] initWithString: request.url];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:requestURL];
    urlRequest.HTTPMethod = RLMHTTPMethodToNSString[request.method];
    if (![urlRequest.HTTPMethod isEqualToString:@"GET"]) {
        urlRequest.HTTPBody = [request.body dataUsingEncoding:NSUTF8StringEncoding];
    }
    urlRequest.timeoutInterval = request.timeout;

    for (NSString *key in request.headers) {
        [urlRequest addValue:request.headers[key] forHTTPHeaderField:key];
    }
    id delegate = [RLMSessionDelegate delegateWithCompletion:completionBlock];
    auto session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                                 delegate:delegate delegateQueue:nil];

    // Add the request to a task and start it
    [[session dataTaskWithRequest:urlRequest] resume];
    // Tell the session to destroy itself once it's done with the request
    [session finishTasksAndInvalidate];
}

@end

#pragma mark RLMSessionDelegate

@implementation RLMSessionDelegate {
    NSData *_data;
    RLMNetworkTransportCompletionBlock _completionBlock;
}

+ (instancetype)delegateWithCompletion:(RLMNetworkTransportCompletionBlock)completion {
    RLMSessionDelegate *delegate = [RLMSessionDelegate new];
    delegate->_completionBlock = completion;
    return delegate;
}

- (void)URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (!_data) {
        _data = data;
        return;
    }
    if (![_data respondsToSelector:@selector(appendData:)]) {
        _data = [_data mutableCopy];
    }
    [(id)_data appendData:data];
}

- (void)URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    RLMResponse *response = [RLMResponse new];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) task.response;
    response.headers = httpResponse.allHeaderFields;
    response.httpStatusCode = httpResponse.statusCode;

    if (error) {
        response.body = [error localizedDescription];
        return _completionBlock(response);
    }

    response.body = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];

    _completionBlock(response);
}

- (RLMSyncErrorResponseModel *)responseModelFromData:(NSData *)data {
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
