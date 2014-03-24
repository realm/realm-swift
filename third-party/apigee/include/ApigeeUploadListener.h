//
//  ApigeeUploadListener.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2013 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @protocol ApigeeUploadListener
 @abstract Protocol (listener) to be called when app monitoring uploads occur
 */
@protocol ApigeeUploadListener <NSObject>

/*!
 @abstract Called when metrics are being uploaded to server
 @param metricsPayload the raw payload of metrics being uploaded to server
 */
- (void)onUploadMetrics:(NSString*)metricsPayload;

/*!
 @abstract Called when a crash report is being uploaded to server
 @param crashReportPayload the raw payload of a crash report being uploaded
    to server
 */
- (void)onUploadCrashReport:(NSString*)crashReportPayload;

@end
