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

@interface RLMSyncNetworkClient ()
@end

@implementation RLMSyncNetworkClient

+ (NSURLSession *)session {
    return [NSURLSession sharedSession];
}

+ (NSURL *)urlForServer:(NSURL *)serverURL endpoint:(RLMSyncServerEndpoint)endpoint {
    NSString *pathComponent = nil;
    switch (endpoint) {
        case RLMSyncServerEndpointSessions:
            pathComponent = @"sessions";
            break;
        case RLMSyncServerEndpointRefresh:
            // TODO: change this once the server-side API changes
            pathComponent = @"sessions"; //@"refresh";
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

    // Add the request to a task and start it
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:^(NSData *data,
                                                                 __attribute__((unused)) NSURLResponse *response,
                                                                 NSError *error) {
                                                 // Parse out the JSON
                                                 NSError *localError = nil;
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
                                                                                      userInfo:nil];
                                                         completionBlock(localError, nil);
                                                     } else {
                                                         // JSON parsed successfully
                                                         completionBlock(nil, (NSDictionary *)json);
                                                     }
                                                 } else {
                                                     // Network error
                                                     completionBlock(error, nil);
                                                 }
                                             }];
    [task resume];
}

@end
