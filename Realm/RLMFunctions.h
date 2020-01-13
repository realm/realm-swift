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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A block type used to asynchronously report results of a remote function call.
/// Data is returned raw as function results are of arbitrary shape.
typedef void(^RLMFunctionCompletionBlock)(NSData * _Nullable, NSError * _Nullable);

/**
 `RLMFunctions` allow a user to call any remote functions they have declared on the
 MongoDB Realm server.
 */
@interface RLMFunctions: NSObject

/**
 Calls the MongoDB Stitch function with the provided name and arguments, ignoring the result of the function.

 - parameter name: The name of the Stitch function to be called.
 - parameter arguments: The `BSONArray` of arguments to be provided to the function.
 - parameter timeout: The timeout for this request.
 - parameter callbackQueue: The dispatch queue to run the function call on.
 - parameter onCompletion: The completion handler to call when the function call is complete.
 This handler is executed on a non-main global `DispatchQueue`.
 */
- (void)callFunction:(NSString *)name
           arguments:(NSArray *)arguments
             timeout:(NSTimeInterval)timeout
       callbackQueue:(dispatch_queue_t)callbackQueue
        onCompletion:(RLMFunctionCompletionBlock)completion NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
