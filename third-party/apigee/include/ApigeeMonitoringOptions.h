//
//  ApigeeMonitoringOptions.h
//  ApigeeiOSSDK
//
//  Copyright (c) 2013 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ApigeeUploadListener.h"

/*!
 @class ApigeeMonitoringOptions
 @abstract Allows developer to configure app monitoring functionality before use
 */
@interface ApigeeMonitoringOptions : NSObject

/*!
 @property monitoringEnabled
 @abstract Controls whether all of app monitoring should be on or off
 @discussion Please be aware that turning this option off will turn off all app
    monitoring functionality
 */
@property(assign, nonatomic) BOOL monitoringEnabled;

/*!
 @property crashReportingEnabled
 @abstract Allows crash reporting functionality to be turned off
 @discussion This would be useful if you already had an existing 3rd party crash
    reporter in place, but still wanted to use the other parts of app monitoring
    functionality.
 */
@property(assign, nonatomic) BOOL crashReportingEnabled;

/*!
 @property interceptNetworkCalls
 @abstract Determines whether automatic interception of network calls made using
    NSURLConnection is enabled (on by default)
 @discussion Since most iOS applications make use of NSURLConnection (either
    directly or indirectly) to performance network calls, this option being
    turned on provides convenient, out-of-box monitoring of network traffic
    without requiring any code changes. This option is not capable of capturing
    metrics on networking calls made using CFNetworking (C library) or BSD
    sockets (C library).
 */
@property(assign, nonatomic) BOOL interceptNetworkCalls;

/*!
 @property interceptNSURLSessionCalls
 @abstract Determines whether automatic interception of network calls made using
    NSURLSession is enabled (off by default)
 @discussion This option is only applicable to iOS 7 (or later) and network
    calls that make use of NSURLSession
 */
@property(assign, nonatomic) BOOL interceptNSURLSessionCalls;

/*!
 @property autoPromoteLoggedErrors
 @abstract Allows messages logged with NSLog("error: ..."); to be treated as
    errors and reported as such.
 @discussion Since many iOS apps use NSLog to log error conditions, this
    mechanism is provided as a convenient means of automatically identifying
    errors with minimal (or no) code changes required to the application.
 */
@property(assign, nonatomic) BOOL autoPromoteLoggedErrors;

/*!
 @property showDebuggingInfo
 @abstract Allows extensive debugging output to be turned on (off by default)
 @discussion Turning this on can be very helpful to troubleshoot when things
    aren't working as expected
 */
@property(assign, nonatomic) BOOL showDebuggingInfo;

/*!
 @property uploadListener
 @abstract Listener to be notified on upload of crash reports and metrics
 @discussion This can be useful if you want to know when uploads are happening
    and to see what's being uploaded.
 @see ApigeeUploadListener ApigeeUploadListener
 */
@property(weak, nonatomic) id<ApigeeUploadListener> uploadListener;

/*!
 @property customUploadUrl
 @abstract Allows for customization of URL where monitoring metrics and crash
    reports are uploaded
 @discussion If you change this value you will not see monitoring metrics nor
    crash reports in the Apigee portal.
 */
@property(copy, nonatomic) NSString* customUploadUrl;

/*!
 @property performAutomaticUIEventTracking
 @abstract Allows for automatic capture of UI events for tracking purposes
 @discussion By default, this parameter is turned off. When turned on, UIViewController,
    UIButton, UISwitch, and UISegmentedControl are swizzled to intercept UI events
    and logged to portal with tag value of 'UI_EVENT'.
 */
@property(assign, nonatomic) BOOL performAutomaticUIEventTracking;

/*!
 @property alwaysUploadCrashReports
 @abstract Determines whether crash reports should be uploaded to Apigee server
    even if device is not part of sample (i.e., not uploading network, logging,
    and error data).
 @discussion By default, this parameter is turned on.
 */
@property(assign, nonatomic) BOOL alwaysUploadCrashReports;


@end
