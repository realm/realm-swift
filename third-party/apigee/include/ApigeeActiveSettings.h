//
//  ApigeeActiveSettings.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import "ApigeeCompositeConfiguration.h"

/*!
 @abstract Categorizes the active configuration
 @constant kApigeeDefault Default configuration (not one of the other types)
 @constant kApigeeABTesting Configuration for A/B testing
 @constant kApigeeDeviceType Configuration specific to a type of device
 @constant kApigeeDeviceLevel Configuration specific to a particular device
 */
typedef enum {
    kApigeeDefault,
    kApigeeABTesting,
    kApigeeDeviceType,
    kApigeeDeviceLevel
} ApigeeActiveConfiguration;

/*!
 @abstract ApigeeActiveSettings represents the configuration settings that
    are in effect to control app monitoring for the current session
 */
@interface ApigeeActiveSettings : NSObject

@property (readonly, nonatomic) NSNumber *instaOpsApplicationId;
@property (readonly, nonatomic) NSString *applicationUUID;
@property (readonly, nonatomic) NSString *organizationUUID;
@property (readonly, nonatomic) NSString *orgName;
@property (readonly, nonatomic) NSString *appName;
@property (readonly, nonatomic) NSString *fullAppName;
@property (readonly, nonatomic) NSString *appOwner;
@property (readonly, nonatomic) NSDate *appCreatedDate;
@property (readonly, nonatomic) NSDate *appLastModifiedDate;
@property (readonly, nonatomic) BOOL monitoringDisabled;
@property (readonly, nonatomic) BOOL deleted;
@property (readonly, nonatomic) NSString *googleId;
@property (readonly, nonatomic) NSString *appleId;
@property (readonly, nonatomic) NSString *appDescription;
@property (readonly, nonatomic) NSString *environment;
@property (readonly, nonatomic) NSString *customUploadUrl;


@property (readonly, nonatomic) NSNumber *abtestingPercentage;

@property (readonly, nonatomic) NSArray *appConfigOverrideFilters;
@property (readonly, nonatomic) NSArray *deviceNumberFilters;
@property (readonly, nonatomic) NSArray *deviceIdFilters;
@property (readonly, nonatomic) NSArray *deviceModelRegexFilters;
@property (readonly, nonatomic) NSArray *devicePlatformRegexFilters;
@property (readonly, nonatomic) NSArray *networkTypeRegexFilters;
@property (readonly, nonatomic) NSArray *networkOperatorRegexFilters;


@property (readonly, nonatomic) ApigeeActiveConfiguration activeConfiguration;
@property (readonly, nonatomic) NSString * activeConfigurationName;

@property (readonly, nonatomic) NSString *settingsDescription;
@property (readonly, nonatomic) NSDate *settingsLastModifiedDate;
@property (readonly, nonatomic) NSArray *urlRegex;
@property (readonly, nonatomic) BOOL networkMonitoringEnabled;
@property (readonly, nonatomic) NSInteger logLevelToMonitor;
@property (readonly, nonatomic) BOOL enableLogMonitoring;
@property (readonly, nonatomic) NSArray *customConfigParams;
@property (readonly, nonatomic) NSArray *deletedCustomConfigParams;
@property (readonly, nonatomic) NSString *appConfigType;
@property (readonly, nonatomic) ApigeeNetworkConfig *networkConfig;
@property (readonly, nonatomic) BOOL cachingEnabled;
@property (readonly, nonatomic) BOOL monitorAllUrls;
@property (readonly, nonatomic) BOOL sessionDataCaptureEnabled;
@property (readonly, nonatomic) BOOL batteryStatusCaptureEnabled;
@property (readonly, nonatomic) BOOL imeicaptureEnabled;
@property (readonly, nonatomic) BOOL obfuscateIMEI;
@property (readonly, nonatomic) BOOL deviceIdCaptureEnabled;
@property (readonly, nonatomic) BOOL obfuscateDeviceId;
@property (readonly, nonatomic) BOOL deviceModelCaptureEnabled;
@property (readonly, nonatomic) BOOL locationCaptureEnabled;
@property (readonly, nonatomic) NSInteger locationCaptureResolution;
@property (readonly, nonatomic) BOOL networkCarrierCaptureEnabled;
@property (readonly, nonatomic) NSInteger appConfigId;
@property (readonly, nonatomic) BOOL enableUploadWhenRoaming;
@property (readonly, nonatomic) BOOL enableUploadWhenMobile;
@property (readonly, nonatomic) NSInteger agentUploadInterval;
@property (readonly, nonatomic) NSInteger agentUploadIntervalInSeconds;
@property (readonly, nonatomic) NSInteger samplingRate;

- (id) initWithConfig:(ApigeeCompositeConfiguration *) compositeConfig;

@end
