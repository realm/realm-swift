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
#import "RLMRealmConfiguration.h"
#import "RLMJSONModels.h"
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
+ (instancetype)delegateWithCertificatePaths:(NSDictionary *)paths
                                  completion:(RLMNetworkTransportCompletionBlock)completion;
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

    RLMSyncManager *syncManager = [RLMSyncManager sharedManagerWithAppConfiguration:nil];
    RLMNetworkRequestOptions *options = syncManager.networkRequestOptions;

    for (NSString *key in request.headers) {
        [urlRequest addValue:request.headers[key] forHTTPHeaderField:key];
    }
    id delegate = [RLMSessionDelegate delegateWithCertificatePaths:options.pinnedCertificatePaths
                                                        completion:completionBlock];
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
    NSDictionary<NSString *, NSURL *> *_certificatePaths;
    NSData *_data;
    RLMNetworkTransportCompletionBlock _completionBlock;
}

+ (instancetype)delegateWithCertificatePaths:(NSDictionary *)paths
                                  completion:(RLMNetworkTransportCompletionBlock)completion {
    RLMSessionDelegate *delegate = [RLMSessionDelegate new];
    delegate->_certificatePaths = paths;
    delegate->_completionBlock = completion;
    return delegate;
}

- (void)URLSession:(__unused NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    auto protectionSpace = challenge.protectionSpace;

    // Just fall back to the default logic for HTTP basic auth
    if (protectionSpace.authenticationMethod != NSURLAuthenticationMethodServerTrust || !protectionSpace.serverTrust) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }

    // If we have a pinned certificate for this hostname, we want to validate
    // against that, and otherwise just do the default thing
    auto certPath = _certificatePaths[protectionSpace.host];
    if (!certPath) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    if ([certPath isKindOfClass:[NSString class]]) {
        certPath = [NSURL fileURLWithPath:(id)certPath];
    }


    // Reject the server auth and report an error if any errors occur along the way
    CFArrayRef items = nil;
    NSError *error;
    auto reportStatus = realm::util::make_scope_exit([&]() noexcept {
        if (items) {
            CFRelease(items);
        }
        if (error) {
            RLMResponse *response = [RLMResponse new];
            NSError * err;
            NSData *errorJSON = [NSJSONSerialization dataWithJSONObject:error.userInfo options:0 error:&err];
            if (!err) {
                response.body = [[NSString alloc] initWithData:errorJSON encoding:NSUTF8StringEncoding];
            } else {
                response.body = error.domain;
            }
            response.customStatusCode = error.code;
            _completionBlock(response);
            // Don't also report errors about the connection itself failing later
            _completionBlock = ^(RLMResponse *) { };
            completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
        }
    });

    NSData *data = [NSData dataWithContentsOfURL:certPath options:0 error:&error];
    if (!data) {
        return;
    }

    // Load our pinned certificate and add it to the anchor set
#if TARGET_OS_IPHONE
    id certificate = (__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
    if (!certificate) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:errSecUnknownFormat userInfo:nil];
        return;
    }
    items = (CFArrayRef)CFBridgingRetain(@[certificate]);
#else
    SecItemImportExportKeyParameters params{
        .version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION
    };
    if (OSStatus status = SecItemImport((__bridge CFDataRef)data, (__bridge CFStringRef)certPath.absoluteString,
                                        nullptr, nullptr, 0, &params, nullptr, &items)) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        return;
    }
#endif
    SecTrustRef serverTrust = protectionSpace.serverTrust;
    if (OSStatus status = SecTrustSetAnchorCertificates(serverTrust, items)) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        return;
    }

    // Only use our certificate and not the ones from the default CA roots
    if (OSStatus status = SecTrustSetAnchorCertificatesOnly(serverTrust, true)) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        return;
    }

    // Verify that our pinned certificate is valid for this connection
    SecTrustResultType trustResult;
    if (OSStatus status = SecTrustEvaluate(serverTrust, &trustResult)) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        return;
    }
    if (trustResult != kSecTrustResultProceed && trustResult != kSecTrustResultUnspecified) {
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
        return;
    }

    completionHandler(NSURLSessionAuthChallengeUseCredential,
                      [NSURLCredential credentialForTrust:protectionSpace.serverTrust]);
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

@implementation RLMNetworkRequestOptions
@end
