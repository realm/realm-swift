//
//  CompositeApplicationConfigurationModel.h
//  ApigeeAppMonitoring
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import "ApigeeMonitorSettings.h"


@interface ApigeeCompositeConfiguration : NSObject

@property (strong, nonatomic) NSNumber *instaOpsApplicationId;
@property (strong, nonatomic) NSString *applicationUUID;
@property (strong, nonatomic) NSString *organizationUUID;
@property (strong, nonatomic) NSString *orgName;
@property (strong, nonatomic) NSString *appName;
@property (strong, nonatomic) NSString *fullAppName;
@property (strong, nonatomic) NSString *appOwner;

@property (strong, nonatomic) NSString *googleId;
@property (strong, nonatomic) NSString *appleId;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSString *environment;
@property (strong, nonatomic) NSString *customUploadUrl;

@property (strong, nonatomic) NSDate *createdDate;
@property (strong, nonatomic) NSDate *lastModifiedDate;

@property (assign, nonatomic) BOOL monitoringDisabled;
@property (assign, nonatomic) BOOL deleted;
@property (assign, nonatomic) BOOL deviceLevelOverrideEnabled;
@property (assign, nonatomic) BOOL deviceTypeOverrideEnabled;
@property (assign, nonatomic) BOOL ABTestingOverrideEnabled;

@property (strong, nonatomic) ApigeeMonitorSettings *defaultSettings;
@property (strong, nonatomic) ApigeeMonitorSettings *deviceLevelSettings;
@property (strong, nonatomic) ApigeeMonitorSettings *deviceTypeSettings;
@property (strong, nonatomic) ApigeeMonitorSettings *abTestingSettings;

@property (strong, nonatomic) NSNumber *abtestingPercentage;

@property (strong, nonatomic) NSArray *appConfigOverrideFilters;
@property (strong, nonatomic) NSArray *deviceNumberFilters;
@property (strong, nonatomic) NSArray *deviceIdFilters;
@property (strong, nonatomic) NSArray *deviceModelRegexFilters;
@property (strong, nonatomic) NSArray *devicePlatformRegexFilters;
@property (strong, nonatomic) NSArray *networkTypeRegexFilters;
@property (strong, nonatomic) NSArray *networkOperatorRegexFilters;


@end
