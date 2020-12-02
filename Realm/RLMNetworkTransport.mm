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

#import "RLMNetworkTransport_Private.hpp"

#import "RLMApp.h"
#import "RLMRealmConfiguration.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/sync/generic_network_transport.hpp>
#import <realm/util/scope_exit.hpp>

using namespace realm;

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

@interface RLMEventSessionDelegate <NSURLSessionDelegate> : NSObject
+ (instancetype)delegateWithEventSubscriber:(RLMEventSubscriber *)subscriber;
@end;

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

- (NSURLSession *)doStreamRequest:(nonnull RLMRequest *)request
                  eventSubscriber:(nonnull id<RLMEventDelegate>)subscriber {
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 30;
    sessionConfig.timeoutIntervalForResource = INT_MAX;
    sessionConfig.HTTPAdditionalHeaders = @{
        @"Content-Type": @"text/event-stream",
        @"Cache": @"no-cache",
        @"Accept": @"text/event-stream"
    };
    id delegate = [RLMEventSessionDelegate delegateWithEventSubscriber:subscriber];
    auto session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                 delegate:delegate
                                            delegateQueue:nil];
    NSURL *url = [[NSURL alloc] initWithString:request.url];
    [[session dataTaskWithURL:url] resume];
    return session;
}

- (RLMRequest *)RLMRequestFromRequest:(const realm::app::Request)request {
    RLMRequest *rlmRequest = [RLMRequest new];
    NSMutableDictionary<NSString *, NSString*> *headersDict = [NSMutableDictionary new];
    for(auto &[key, value] : request.headers) {
        [headersDict setValue:@(value.c_str()) forKey:@(key.c_str())];
    }
    rlmRequest.headers = headersDict;
    rlmRequest.method = static_cast<RLMHTTPMethod>(request.method);
    rlmRequest.timeout = request.timeout_ms;
    rlmRequest.url = @(request.url.c_str());
    rlmRequest.body = @(request.body.c_str());
    return rlmRequest;
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

@end

@implementation RLMEventSessionDelegate {
    RLMEventSubscriber *_subscriber;
    bool _hasOpened;
}

+ (instancetype)delegateWithEventSubscriber:(RLMEventSubscriber *)subscriber {
    RLMEventSessionDelegate *delegate = [RLMEventSessionDelegate new];
    delegate->_subscriber = subscriber;
    return delegate;
}

- (void)URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (!_hasOpened) {
        _hasOpened = true;
        [_subscriber didOpen];
    }

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) dataTask.response;
    if (httpResponse.statusCode != 200) {
        NSString *errorStatus = [NSString stringWithFormat:@"URLSession HTTP error code: %ld",
                                 (long)httpResponse.statusCode];
        NSError *error = [NSError errorWithDomain:RLMErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: errorStatus}];
        return [_subscriber didCloseWithError:error];
    }
    [_subscriber didReceiveEvent:data];
}

- (void)URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    RLMResponse *response = [RLMResponse new];
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) task.response;
    response.headers = httpResponse.allHeaderFields;
    response.httpStatusCode = httpResponse.statusCode;

    // -999 indicates that the session was cancelled.
    if (error && (error.code != -999)) {
        response.body = [error localizedDescription];
        return [_subscriber didCloseWithError:error];
    } else if (error && (error.code == -999)) {
        return [_subscriber didCloseWithError:nil];
    }

    if (response.httpStatusCode != 200) {
        NSString *errorStatus = [NSString stringWithFormat:@"URLSession HTTP error code: %ld",
                                 (long)httpResponse.statusCode];
        NSError *error = [NSError errorWithDomain:RLMErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: errorStatus}];
        return [_subscriber didCloseWithError:error];
    }
}

@end
