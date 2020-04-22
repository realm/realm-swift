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

#import <Realm/RLMConstants.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLMNetworkRequestOptions : NSObject
@property (nonatomic, copy, nullable) NSString *authorizationHeaderName;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *customHeaders;
@property (nullable, nonatomic, copy) NSDictionary<NSString *, NSURL *> *pinnedCertificatePaths;
@end

typedef RLM_CLOSED_ENUM(int32_t, RLMHTTPMethod) {
    RLMHTTPMethodGET    = 0,
    RLMHTTPMethodPOST   = 1,
    RLMHTTPMethodPATCH  = 2,
    RLMHTTPMethodPUT    = 3,
    RLMHTTPMethodDELETE = 4
};

/// An HTTP request that can be made to an arbitrary server.
@interface RLMRequest : NSObject

/// The HTTP method of this request.
@property (nonatomic, assign) RLMHTTPMethod method;

/// The URL to which this request will be made.
@property (nonatomic, strong) NSString *url;

/// The number of milliseconds that the underlying transport should spend on an
/// HTTP round trip before failing with an error.
@property (nonatomic, assign) NSTimeInterval timeout;

/// The HTTP headers of this request.
@property (nonatomic, strong) NSDictionary<NSString *, NSString *>* headers;

/// The body of the request.
@property (nonatomic, strong) NSString* body;

@end

/// The contents of an HTTP response.
@interface RLMResponse : NSObject

/// The status code of the HTTP response.
@property (nonatomic, assign) NSInteger httpStatusCode;

/// A custom status code provided by the SDK.
@property (nonatomic, assign) NSInteger customStatusCode;

/// The headers of the HTTP response.
@property (nonatomic, strong) NSDictionary<NSString *, NSString *>* headers;

/// The body of the HTTP response.
@property (nonatomic, strong) NSString *body;

@end

typedef void(^RLMNetworkTransportCompletionBlock)(RLMResponse *);

/// Transporting protocol for foreign interfaces. Allows for custom
/// request/response handling.
@protocol RLMNetworkTransport <NSObject>

/**
 Sends a request to a given endpoint.

 @param request The request to send.
 @param completionBlock A callback invoked on completion of the request.
*/
- (void)sendRequestToServer:(RLMRequest *) request
                 completion:(RLMNetworkTransportCompletionBlock)completionBlock;

@end

@interface RLMNetworkTransport : NSObject<RLMNetworkTransport>

- (void)sendRequestToServer:(RLMRequest *) request
                 completion:(RLMNetworkTransportCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
