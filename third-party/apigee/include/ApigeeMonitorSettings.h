//
//  ApigeeMonitorSettings.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import "ApigeeNetworkConfig.h"


@interface ApigeeMonitorSettings : NSObject

@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSDate *lastModifiedDate;
@property (strong, nonatomic) NSArray *urlRegex;
@property (assign, nonatomic) BOOL networkMonitoringEnabled;
@property (assign, nonatomic) NSInteger logLevelToMonitor;
@property (assign, nonatomic) BOOL enableLogMonitoring;
@property (strong, nonatomic) NSArray *customConfigParams;
@property (strong, nonatomic) NSArray *deletedCustomConfigParams;
@property (strong, nonatomic) NSString *appConfigType;
@property (strong, nonatomic) ApigeeNetworkConfig *networkConfig;
@property (assign, nonatomic) BOOL cachingEnabled;
@property (assign, nonatomic) BOOL monitorAllUrls;
@property (assign, nonatomic) BOOL sessionDataCaptureEnabled;
@property (assign, nonatomic) BOOL batteryStatusCaptureEnabled;
@property (assign, nonatomic) BOOL imeicaptureEnabled;
@property (assign, nonatomic) BOOL obfuscateIMEI;
@property (assign, nonatomic) BOOL deviceIdCaptureEnabled;
@property (assign, nonatomic) BOOL obfuscateDeviceId;
@property (assign, nonatomic) BOOL deviceModelCaptureEnabled;
@property (assign, nonatomic) BOOL locationCaptureEnabled;
@property (assign, nonatomic) NSInteger locationCaptureResolution;
@property (assign, nonatomic) BOOL networkCarrierCaptureEnabled;
@property (assign, nonatomic) NSInteger appConfigId;
@property (assign, nonatomic) BOOL enableUploadWhenRoaming;
@property (assign, nonatomic) BOOL enableUploadWhenMobile;
@property (assign, nonatomic) NSInteger agentUploadInterval;
@property (assign, nonatomic) NSInteger agentUploadIntervalInSeconds;
@property (assign, nonatomic) NSInteger samplingRate;

@end
