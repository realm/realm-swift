//
//  NSString+Apigee.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @category NSString (Apigee)
 @discussion This category provides methods that capture network performance
 metrics on built-in NSString methods that perform network calls.
 */
@interface NSString (Apigee)

/*!
 @abstract Returns a string created by reading data from a given URL interpreted
    using a given encoding.
 @param url The URL to read.
 @param enc The encoding of the data at url.
 @param error If an error occurs, upon returns contains an NSError object that
    describes the problem. If you are not interested in possible errors, you may
    pass in NULL.
 @return A string created by reading data from URL using the encoding, enc. If
    the URL can’t be opened or there is an encoding error, returns nil.
 @discussion This method simply calls the NSString class method
    stringWithContentsOfURL:encoding:error: while capturing the network performance
    metrics for that call.
 */
+ (NSString*) stringWithTimedContentsOfURL:(NSURL *) url
                                  encoding:(NSStringEncoding) enc
                                     error:(NSError **) error;

/*!
 @abstract Returns a string created by reading data from a given URL and returns
    by reference the encoding used to interpret the data.
 @param url The URL from which to read data.
 @param enc Upon return, if url is read successfully, contains the encoding used
    to interpret the data.
 @param error If an error occurs, upon returns contains an NSError object that
    describes the problem. If you are not interested in possible errors, you may
    pass in NULL.
 @return A string created by reading data from url. If the URL can’t be opened
    or there is an encoding error, returns nil.
 @discussion This method simply calls the NSString class method
    stringWithContentsOfURL:usedEncoding:error: while capturing the network
    performance metrics for that call.
 */
+ (NSString*) stringWithTimedContentsOfURL:(NSURL *) url
                              usedEncoding:(NSStringEncoding *) enc
                                     error:(NSError **) error;

/*!
 @abstract Returns an NSString object initialized by reading data from a given
    URL interpreted using a given encoding.
 @param url The URL to read.
 @param enc The encoding of the file at url.
 @param error If an error occurs, upon returns contains an NSError object that
    describes the problem. If you are not interested in possible errors, pass
    in NULL.
 @return An NSString object initialized by reading data from url. If the URL
    can’t be opened or there is an encoding error, returns nil.
 @discussion This method simply calls the NSString instance method
    initWithContentsOfURL:encoding:error: while capturing the network
    performance metrics for that call.
 */
- (id) initWithTimedContentsOfURL:(NSURL *) url
                         encoding:(NSStringEncoding) enc
                            error:(NSError **) error;

/*!
 @abstract Returns an NSString object initialized by reading data from a given
    URL and returns by reference the encoding used to interpret the data.
 @param url The URL from which to read data.
 @param enc Upon return, if url is read successfully, contains the encoding
    used to interpret the data.
 @param error If an error occurs, upon returns contains an NSError object that
    describes the problem. If you are not interested in possible errors, pass
    in NULL.
 @return An NSString object initialized by reading data from url. If url can’t
    be opened or the encoding cannot be determined, returns nil.
 @discussion  This method simply calls the NSString instance method
    initWithContentsOfURL:usedEncoding:error: while capturing the network
    performance metrics for that call.
 */
- (id) initWithTimedContentsOfURL:(NSURL *) url
                     usedEncoding:(NSStringEncoding *) enc
                            error:(NSError **) error;

// convenience methods
/*!
 @internal
 */
- (BOOL) containsString:(NSString *)substringToLookFor;

@end
