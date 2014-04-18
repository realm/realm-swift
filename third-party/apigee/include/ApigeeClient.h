//
//  ApigeeClient.h
//  ApigeeiOSSDK
//
//  Copyright (c) 2013 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApigeeAppIdentification;
@class ApigeeMonitoringClient;
@class ApigeeMonitoringOptions;


/*!
 @class ApigeeClient
 @abstract Top-level class for interfacing with Apigee SDK
 */
@interface ApigeeClient : NSObject

/*!
 @abstract Initializes Apigee client object using org name and app name
 @param organizationId Identifier for your organization
 @param applicationId Identifier for your application
 @return initialized instance of ApigeeClient
 */
- (id)initWithOrganizationId:(NSString*)organizationId
               applicationId:(NSString*)applicationId;

/*!
 @abstract Initializes Apigee client object using org name, app name, and base URL
 @param organizationId Identifier for your organization
 @param applicationId Identifier for your application
 @param baseURL URL for server
 @return initialized instance of ApigeeClient
 @discussion The baseURL parameter should not be specified (can be nil) unless
    directed to do so by Apigee
 */
- (id)initWithOrganizationId:(NSString*)organizationId
               applicationId:(NSString*)applicationId
                     baseURL:(NSString*)baseURL;

/*!
 @abstract Initializes Apigee client object using org name, app name, base URL, urlTerms
 @param organizationId Identifier for your organization
 @param applicationId Identifier for your application
 @param baseURL URL for server
 @param urlTerms Default string og URL params to append to all API calls
 @return initialized instance of ApigeeClient
 @discussion The baseURL parameter should not be specified (can be nil) unless
 directed to do so by Apigee
 */
- (id)initWithOrganizationId:(NSString*)organizationId
               applicationId:(NSString*)applicationId
                     baseURL:(NSString*)baseURL
                     urlTerms:(NSString*)urlTerms;

/*!
 @abstract Initializes Apigee client object using org name, app name, and
    ApigeeMonitoringOptions
 @param organizationId Identifier for your organization
 @param applicationId Identifier for your application
 @param monitoringOptions The options to use for app monitoring
 @see ApigeeMonitoringOptions ApigeeMonitoringOptions
 @return initialized instance of ApigeeClient
 */
- (id)initWithOrganizationId:(NSString*)organizationId
               applicationId:(NSString*)applicationId
                     options:(ApigeeMonitoringOptions*)monitoringOptions;

/*!
 @abstract Initializes Apigee client object using org name, app name, base URL,
    and ApigeeMonitoringOptions
 @param organizationId Identifier for your organization
 @param applicationId Identifier for your application
 @param baseURL URL for server
 @param monitoringOptions The options to use for app monitoring
 @see ApigeeMonitoringOptions ApigeeMonitoringOptions
 @return initialized instance of ApigeeClient
 @discussion The baseURL parameter should not be specified (can be nil) unless
    directed to do so by Apigee
 */
- (id)initWithOrganizationId:(NSString*)organizationId
               applicationId:(NSString*)applicationId
                     baseURL:(NSString*)baseURL
                     options:(ApigeeMonitoringOptions*)monitoringOptions;


/*!
 @abstract Retrieves the Apigee app monitoring client
 @see ApigeeMonitoringClient ApigeeMonitoringClient
 @return the ApigeeMonitoringClient instance that was initialized
 */
- (ApigeeMonitoringClient*)monitoringClient;

/*!
 @abstract Retrieves the object with identification parameters for the current application
 @see ApigeeAppIdentification ApigeeAppIdentification
 @return the ApigeeAppIdentification object associated with the current application
 */
- (ApigeeAppIdentification*)appIdentification;

/*!
 @abstract Retrieves the version string for the Apigee iOS SDK
 @return version string for the Apigee iOS SDK
 */
+ (NSString*)sdkVersion;

@end
