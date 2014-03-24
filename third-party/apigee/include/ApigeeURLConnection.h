//
//  ApigeeURLConnection.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @abstract Subclassed NSURLConnection with built-in network performance capture
 */
@interface ApigeeURLConnection : NSURLConnection

+ (NSURLConnection *) connectionWithRequest:(NSURLRequest *) request delegate:(id < NSURLConnectionDelegate >) delegate;
+ (NSData *) sendSynchronousRequest:(NSURLRequest *) request
                       returningResponse:(NSURLResponse **)response
                                   error:(NSError **)error;
+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

- (id) initWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate;
- (id) initWithRequest:(NSURLRequest *)request delegate:(id < NSURLConnectionDelegate >)delegate startImmediately:(BOOL)startImmediately;
- (void) start;

@end
