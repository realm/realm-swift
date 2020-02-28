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

#import <Foundation/Foundation.h>

#import "RLMSyncUtil_Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface RLMNetworkRequestOptions : NSObject
@property (nonatomic, copy, nullable) NSString *authorizationHeaderName;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *customHeaders;
@property (nullable, nonatomic, copy) NSDictionary<NSString *, NSURL *> *pinnedCertificatePaths;
@end

typedef enum RLMHTTPMethod {
    GET, POST, PUT, PATCH, DELETE
} RLMHTTPMethod;

@interface RLMRequest : NSObject
/**
 * The HTTP method of this request.
 */
@property RLMHTTPMethod method;

/**
 * The URL to which this request will be made.
 */
@property NSString* url;

/**
 * The number of milliseconds that the underlying transport should spend on an HTTP round trip before failing with an
 * error.
 */
@property NSUInteger timeoutMS;

/**
 * The HTTP headers of this request.
 */
@property NSDictionary<NSString *, NSString *>* headers;

/**
 * The body of the request.
 */
@property NSString* body;

@end

@interface RLMResponse : NSObject

/**
 * The status code of the HTTP response.
 */
@property NSInteger httpStatusCode;

/**
 * A custom status code provided by the language binding.
 */
@property NSInteger customStatusCode;

/**
 * The headers of the HTTP response.
 */
@property NSDictionary<NSString *, NSString *>* headers;

/**
 * The body of the HTTP response.
 */
@property NSString* body;

@end

typedef void(^RLMNetworkTransportCompletionBlock)(RLMResponse *);

@protocol RLMNetworkTransporting <NSObject>

-(void) sendRequestToServer:(RLMRequest *) request
                 completion:(RLMNetworkTransportCompletionBlock)completionBlock;

@end

/// An abstract class representing a server endpoint.
@interface RLMNetworkTransport : NSObject<RLMNetworkTransporting>

-(void) sendRequestToServer:(RLMRequest *) request
                 completion:(RLMNetworkTransportCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
