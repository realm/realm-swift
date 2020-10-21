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

/// Allowed HTTP methods to be used with `RLMNetworkTransport`.
typedef RLM_CLOSED_ENUM(int32_t, RLMHTTPMethod) {
    /// GET is used to request data from a specified resource.
    RLMHTTPMethodGET    = 0,
    /// POST is used to send data to a server to create/update a resource.
    RLMHTTPMethodPOST   = 1,
    /// PATCH is used to send data to a server to update a resource.
    RLMHTTPMethodPATCH  = 2,
    /// PUT is used to send data to a server to create/update a resource.
    RLMHTTPMethodPUT    = 3,
    /// The DELETE method deletes the specified resource.
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

/// Delegate which is used for subscribing to changes.
@protocol RLMEventDelegate <NSObject>
/// Invoked when a change event has been received.
/// @param event The change event encoded as NSData
- (void)didReceiveEvent:(NSData *)event;
/// A error has occured while subscribing to changes.
/// @param error The error that has occured.
- (void)didReceiveError:(NSError *)error;
/// The stream was opened.
- (void)didOpen;
/// The stream has been closed.
/// @param error The error that has occured.
- (void)didCloseWithError:(NSError *)error;

@end

/// A block for receiving an `RLMResponse` from the `RLMNetworkTransport`.
typedef void(^RLMNetworkTransportCompletionBlock)(RLMResponse *);

/// Transporting protocol for foreign interfaces. Allows for custom
/// request/response handling.
@protocol RLMNetworkTransport <NSObject>

/**
 Sends a request to a given endpoint.

 @param request The request to send.
 @param completionBlock A callback invoked on completion of the request.
*/
- (void)sendRequestToServer:(RLMRequest *)request
                 completion:(RLMNetworkTransportCompletionBlock)completionBlock;

/// Starts an event stream request.
/// @param request The RLMRequest to start.
/// @param subscriber The RLMEventDelegate which will subscribe to changes from the server.
- (NSURLSession *)doStreamRequest:(RLMRequest *)request
                  eventSubscriber:(id<RLMEventDelegate>)subscriber;

@end

/// Transporting protocol for foreign interfaces. Allows for custom
/// request/response handling.
@interface RLMNetworkTransport : NSObject<RLMNetworkTransport>

/**
 Sends a request to a given endpoint.

 @param request The request to send.
 @param completionBlock A callback invoked on completion of the request.
*/
- (void)sendRequestToServer:(RLMRequest *) request
                 completion:(RLMNetworkTransportCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
