/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <Foundation/Foundation.h>

#import "RLMArray.h"
#import "RLMObject.h"


/**
 Success Block Type
 
 */
typedef void (^RLMNetworkSuccessBlock)(void);

/**
 Success Block Type

 @param object    The RLMObject created from the returned JSON data.
 */
typedef void(^RLMNetworkSuccessBlockWithRLMObject)(RLMObject *);

/**
 Success Block Type for multiple objects

 @param object    The RLMObject created from the returned JSON data.
 */
typedef void(^RLMNetworkSuccessBlockWithRLMArray)(RLMArray *);


/**
 Failure Block Type
 
 @param error   The error.
 */
typedef void(^RLMNetworkFailureBlock)(NSError **);

@interface RLMNetworking : NSObject

/**---------------------------------------------------------------------------------------
 * get from URL
 * ---------------------------------------------------------------------------------------
 */
/**
 Gets data asynchronously from a URL, parses the JSON as an RLMObject. If multiple
 objects are returned, only the first object will be created as an RLMObject.
 
 @param request     The URL request.
 @param withClass   The RLMObject class.
 @param whenSuccess Block to be executed when request succeed, nil to ignore.
 @param whenFailure Block to execute in case of an error, nil to ignore.
 */
+(void) getObjectFromURL:(NSURLRequest *)request
               withClass:(Class)objectClass
             whenSuccess:(RLMNetworkSuccessBlockWithRLMObject)success
             whenFailure:(RLMNetworkFailureBlock)failure;

/**
 Gets data asynchronously from a URL, parses the JSON as an RLMObject.

 @param request     The URL request.
 @param withClass   The RLMObject class.
 @param whenSuccess Block to be executed when request succeed, nil to ignore.
 @param whenFailure Block to execute in case of an error, nil to ignore.
 */
+(void) getObjectsFromURL:(NSURLRequest *)request
                withClass:(Class)objectClass
              whenSuccess:(RLMNetworkSuccessBlockWithRLMArray)success
              whenFailure:(RLMNetworkFailureBlock)failure;

// FIXME: add synchronous variants of above

/**---------------------------------------------------------------------------------------
 * send to URL
 * ---------------------------------------------------------------------------------------
 */

/**
 Sends data asynchronously to URL using HTTP PUT

 @param request The URL request.
 @param withObject  An RLMObject to send.
 @param whenSuccess Block to be executed when request succeed, nil to ignore.
 @param whenFailure Block to execute in case of an error, nil to ignore.
 */
+(void) putObjectsToURL:(NSURLRequest *)request
             withObject:(RLMArray *)objects
            whenSuccess:(RLMNetworkSuccessBlock)success
            whenFailure:(RLMNetworkFailureBlock)failure;



/**
 Sends data asynchronously to URL using HTTP PUT
 
 @param request The URL request.
 @param withObjects An RLMArray of objects to send.
 @param whenSuccess Block to be executed when request succeed, nil to ignore.
 @param whenFailure Block to execute in case of an error, nil to ignore.
 */
+(void) putObjectsToURL:(NSURLRequest *)request
            withObjects:(RLMArray *)objects
            whenSuccess:(RLMNetworkSuccessBlock)success
            whenFailure:(RLMNetworkFailureBlock)failure;


/**
 Sends data asynchronously to URL using HTTP POST

 @param request The URL request.
 @param withObject  An RLMObject to send.
 @param whenSuccess Block to be executed when request succeed, nil to ignore.
 @param whenFailure Block to execute in case of an error, nil to ignore.
 */
+(void) postObjectsToURL:(NSURLRequest *)request
              withObject:(RLMArray *)objects
             whenSuccess:(RLMNetworkSuccessBlock)success
             whenFailure:(RLMNetworkFailureBlock)failure;



/**
 Sends data asynchronously to URL using HTTP POST

 @param request The URL request.
 @param withObjects An RLMArray of objects to send.
 @param whenSuccess Block to be executed when request succeed, nil to ignore.
 @param whenFailure Block to execute in case of an error, nil to ignore.
 */
+(void) postObjectsToURL:(NSURLRequest *)request
             withObjects:(RLMArray *)objects
             whenSuccess:(RLMNetworkSuccessBlock)success
             whenFailure:(RLMNetworkFailureBlock)failure;


// FIXME: add synchronous variants of above
@end
