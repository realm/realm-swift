//
//  ApigeeMonitoringClient.h
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import "ApigeeActiveSettings.h"
#import "ApigeeUploadListener.h"

@class ApigeeAppIdentification;
@class ApigeeMonitoringOptions;
@class ApigeeNSURLSessionDataTaskInfo;
@class ApigeeNetworkEntry;

/*!
 @class ApigeeMonitoringClient
 @abstract Top-level class for interfacing with app monitoring functionality
 */
@interface ApigeeMonitoringClient : NSObject //<ApigeeUIEventListener>

/*!
 @property apigeeDeviceId
 @abstract Retrieves that unique device ID used by Apigee to identify the device
 */
@property (strong,readonly) NSString *apigeeDeviceId;

@property (strong, nonatomic) ApigeeActiveSettings *activeSettings;


/*!
 @abstract Retrieves the SDK version
 @return string version of SDK
 */
+ (NSString*)sdkVersion;



/*!
 @abstract Returns the shared instance of ApigeeMonitoringClient.
 @discussion This method is provided as a convenience method. Ideally, your app
    delegate should maintain a reference to the single instance of
    ApigeeMonitoringClient.
 
 @return instance of ApigeeMonitoringClient
 */
+ (id)sharedInstance;

/*!
 @abstract Initializes ApigeeMonitoringClient which controls the Apigee mobile agent.
 @param appIdentification the identification attributes for your application
 @param dataClient the data client object initialized by Apigee SDK
 @return initialized instance of ApigeeMonitoringClient
 */
- (id) initWithAppIdentification:(ApigeeAppIdentification*)appIdentification;

/*!
 @abstract Initializes ApigeeMonitoringClient which controls the Apigee mobile agent.
 @param appIdentification the identification attributes for your application
 @param dataClient the data client object initialized by Apigee SDK
 @param monitoringOptions the options desired for monitoring
 @return initialized instance of ApigeeMonitoringClient
 @see ApigeeMonitoringOptions ApigeeMonitoringOptions
 */
- (id) initWithAppIdentification:(ApigeeAppIdentification*)appIdentification
                         options:(ApigeeMonitoringOptions*)monitoringOptions;

/*!
 @abstract Initializes ApigeeMonitoringClient which controls the Apigee mobile agent.
 @deprecated in version 2.0 - please use initializer that accepts ApigeeMonitoringOptions
 @param appIdentification the identification attributes for your application
 @param dataClient the data client object initialized by Apigee SDK
 @param crashReportingEnabled determines whether crash reports should be uploaded
    to server (allows you to opt-out of crash reports)
 @return initialized instance of ApigeeMonitoringClient
 */
- (id) initWithAppIdentification: (ApigeeAppIdentification*) appIdentification
                  crashReporting: (BOOL) crashReportingEnabled __attribute__ ((deprecated));

/*!
 @abstract Initializes ApigeeMonitoringClient which controls the Apigee mobile agent.
 @deprecated in version 2.0 - please use initializer that accepts ApigeeMonitoringOptions
 @param appIdentification the identification attributes for your application
 @param dataClient the data client object initialized by Apigee SDK
 @param crashReportingEnabled determines whether crash reports should be uploaded
    to server (allows you to opt-out of crash reports)
 @param autoInterceptCalls determines whether automatic interception of network
    calls is enabled (allows you to opt-out)
 @return initialized instance of ApigeeMonitoringClient
 */
- (id) initWithAppIdentification: (ApigeeAppIdentification*) appIdentification
                  crashReporting: (BOOL) crashReportingEnabled
           interceptNetworkCalls: (BOOL) autoInterceptCalls __attribute__ ((deprecated));

/*!
 @abstract Initializes ApigeeMonitoringClient which controls the Apigee mobile agent.
 @deprecated in version 2.0 - please use initializer that accepts ApigeeMonitoringOptions
 @param appIdentification the identification attributes for your application
 @param dataClient the data client object initialized by Apigee SDK
 @param crashReportingEnabled determines whether crash reports should be uploaded
    to server (allows you to opt-out of crash reports)
 @param autoInterceptCalls determines whether automatic interception of network
    calls is enabled (allows you to opt-out)
 @param uploadListener listener to be notified on upload of crash reports and metrics
 @return initialized instance of ApigeeMonitoringClient
 */
- (id) initWithAppIdentification: (ApigeeAppIdentification*) appIdentification
                  crashReporting: (BOOL) crashReportingEnabled
           interceptNetworkCalls: (BOOL) autoInterceptCalls
                  uploadListener: (id<ApigeeUploadListener>)uploadListener __attribute__ ((deprecated));

/*!
 @abstract Answers the question of whether the device session is participating in the sampling
 of metrics.
 @discussion An app configuration of 100% would cause this method to always return YES,
 while an app configuration of 0% would cause this method to always return NO.
 Intermediate values of sampling percentage will cause a random YES/NO to be returned
 with a probability equal to the sampling percentage configured for the app.
 @return boolean indicating whether device session is participating in metrics sampling
 */
- (BOOL)isParticipatingInSample;

/*!
 @abstract Answers the question of whether the device is currently connected to a network
 (either WiFi or cellular).
 @return boolean indicating whether device currently has network connectivity
 */
- (BOOL)isDeviceNetworkConnected;

/*!
 @abstract Retrieves all customer configuration parameter keys that belong to the
 specified category.
 @param category the category whose keys are desired
 @return array of keys belonging to category, or nil if no keys exist
 */
- (NSArray*)customConfigPropertyKeysForCategory:(NSString*)category;

/*!
 @abstract Retrieves the value for the specified custom configuration parameter.
 @param key the key name for the desired custom configuration parameter
 @return value associated with key, or nil if no property exists
 */
- (NSString*)customConfigPropertyValueForKey:(NSString*)key;

/*!
 @abstract Retrieves the value for the specified custom configuration parameter.
 @param key the key name for the desired custom configuration parameter
 @param categoryName the category for the desired custom configuration parameter
 @return value associated with key and category, or nil if no property exists
 */
- (NSString*)customConfigPropertyValueForKey:(NSString *)key
                                 forCategory:(NSString*)categoryName;

/*!
 @abstract Forces device metrics to be uploaded synchronously.
 @return boolean indicating whether metrics were able to be uploaded
 */
- (BOOL)uploadMetrics;

/*!
 @abstract Forces upload of metrics asynchronously
 @param completionHandler a completion handler to run when the upload completes
 */
- (void)asyncUploadMetrics:(void (^)(BOOL))completionHandler;

/*!
 @abstract Forces synchronous update (re-read) of configuration information.
 @return boolean indicating whether the re-read of configuration parameters
 was successful
 */
- (BOOL)refreshConfiguration;

/*!
 @abstract Force update (re-read) of configuration asynchronously
 @param completionHandler a completion handler to run when the refresh completes
 */
- (void)asyncRefreshConfiguration:(void (^)(BOOL))completionHandler;

/*!
 @abstract Determine if monitoring is currently paused
 @return boolean indicating whether monitoring is currently paused
 */
- (BOOL)isPaused;

/*!
 @abstract Pauses monitoring
 @discussion If monitoring is already paused when pause is called, there is no
            change to monitoring functionality, but a log message is generated.
 */
- (void)pause;

/*!
 @abstract Resumes monitoring after being paused.
 @discussion If monitoring is not paused when resume is called, there is no
            change to monitoring functionality, but a log message is generated.
 */
- (void)resume;

/*!
 @abstract Adds an upload listener (observer) that will be notified when uploads
    are sent to server
 @param uploadListener the listener to add (and be called) when uploads occur
 @return boolean indicating whether the listener was added
 */
- (BOOL)addUploadListener:(id<ApigeeUploadListener>)uploadListener;

/*!
 @abstract Removes an upload listener (observer)
 @param uploadListener the listener to remove so that it's no longer called
 @return boolean indicating whether the listener was removed
 */
- (BOOL)removeUploadListener:(id<ApigeeUploadListener>)uploadListener;

/*!
 @abstract Records a successful network call.
 @param url the url accessed
 @param startTime the time when the call was initiated
 @param endTime the time when the call completed
 @return boolean indicating whether the recording was made or not
 */
- (BOOL)recordNetworkSuccessForUrl:(NSString*)url
                         startTime:(uint64_t)startTime
                           endTime:(uint64_t)endTime;

/*!
 @abstract Records a failed network call.
 @param url the url accessed
 @param startTime the time when the call was initiated
 @param endTime the time when the call failed
 @param errorDescription description of the error encountered
 @return boolean indicating whether the recording was made or not
 */
- (BOOL)recordNetworkFailureForUrl:(NSString*)url
                         startTime:(uint64_t)startTime
                           endTime:(uint64_t)endTime
                             error:(NSString*)errorDescription;

/*!
 @abstract Retrieves the unique string identifier for the current app
 @return unique string identifier for app
 */
- (NSString*)uniqueIdentifierForApp;

/*!
 @abstract Retrieves the base URL path used by monitoring
 @return string indicating base URL path used by monitoring
 */
- (NSString*)baseURLPath;

/** The following methods are advanced methods intended to be used in
   conjunction with our C API. They would not be needed for a typical
   Objective-C application. */

/*!
 @abstract Retrieves the time that the mobile agent was initialized (i.e., startup time)
 @return date object representing mobile agent startup time
 */
- (NSDate*)timeStartup;

/*!
 @abstract Retrieves the time that the mobile agent was initialized
    (i.e., startup time)
 @return time in seconds representing mobile agent startup time
 */
- (CFTimeInterval)timeStartupSeconds;

/*!
 @abstract Retrieves the time that the mobile agent last uploaded metrics
    to portal
 @return Time in seconds since device was started representing time of last metrics
    upload (or 0 if no upload has occurred)
 */
- (CFTimeInterval)timeLastUpload;

/*!
 @abstract Retrieves the time that the mobile agent last recognized a
    network transmission
 @return Time in seconds since device was started (or 0 if none has occurred)
 */
- (CFTimeInterval)timeLastNetworkTransmission;

/*
- (void) updateLastNetworkTransmissionTime:(NSString*) networkTransmissionTime;
*/

/*!
 @internal
 */
- (void)recordNetworkEntry:(ApigeeNetworkEntry*)entry;

// the following methods are used for auto-capture of network performance
// with NSURLSession. they are for internal use within the framework only.
#ifdef __IPHONE_7_0
/*!
 @internal
 */
- (id)generateIdentifierForDataTask;

/*!
 @internal
 */
- (void)registerDataTaskInfo:(ApigeeNSURLSessionDataTaskInfo*)dataTaskInfo
              withIdentifier:(id)identifier;

/*!
 @internal
 */
- (ApigeeNSURLSessionDataTaskInfo*)dataTaskInfoForIdentifier:(id)identifier;

/*!
 @internal
 */
- (ApigeeNSURLSessionDataTaskInfo*)dataTaskInfoForTask:(NSURLSessionTask*)task;

/*!
 @internal
 */
- (void)removeDataTaskInfoForIdentifier:(id)identifier;

/*!
 @internal
 */
- (void)removeDataTaskInfoForTask:(NSURLSessionTask*)task;

/*!
 @internal
 */
- (void)recordStartTimeForSessionDataTask:(NSURLSessionDataTask*)dataTask;

#endif

@end
