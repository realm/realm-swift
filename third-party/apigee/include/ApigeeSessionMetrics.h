//
//  SessionMetricEntry.h
//  ApigeeAppMonitoring
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

@interface ApigeeSessionMetrics : NSObject

    @property (strong, nonatomic) NSString *appConfigType;
    @property (strong, nonatomic) NSString *appId;
    @property (strong, nonatomic) NSString *applicationVersion;
    @property (strong, nonatomic) NSString *batteryLevel;
    @property (strong, nonatomic) NSString *bearing;
    @property (strong, nonatomic) NSString *deviceCountry;
    @property (strong, nonatomic) NSString *deviceId;
    @property (strong, nonatomic) NSString *deviceModel;
    @property (strong, nonatomic) NSString *deviceOSVersion;
    @property (strong, nonatomic) NSString *devicePlatform;
    @property (strong, nonatomic) NSString *deviceType;
    @property (strong, nonatomic) NSString *endDay;
    @property (strong, nonatomic) NSString *endHour;
    @property (strong, nonatomic) NSString *endMinute;
    @property (strong, nonatomic) NSString *endMonth;
    @property (strong, nonatomic) NSString *endWeek;
    @property (strong, nonatomic) NSString *identifier;
    @property (strong, nonatomic) NSString *isNetworkChanged;
    @property (strong, nonatomic) NSString *isNetworkRoaming;
    @property (strong, nonatomic) NSString *latitude;
    @property (strong, nonatomic) NSString *localCountry;
    @property (strong, nonatomic) NSString *localLanguage;
    @property (strong, nonatomic) NSString *longitude;
    @property (strong, nonatomic) NSString *networkCarrier;
    @property (strong, nonatomic) NSString *networkCountry;
    @property (strong, nonatomic) NSString *networkExtraInfo;
    @property (strong, nonatomic) NSString *networkSubType;
    @property (strong, nonatomic) NSString *networkType;
    @property (strong, nonatomic) NSString *networkTypeName;
    @property (strong, nonatomic) NSString *sdkVersion;
    @property (strong, nonatomic) NSString *sdkType;
    @property (strong, nonatomic) NSString *sessionId;
    @property (strong, nonatomic) NSString *sessionStartTime;
    @property (strong, nonatomic) NSString *telephonyDeviceId;
    @property (strong, nonatomic) NSString *telephonyNetworkType;
    @property (strong, nonatomic) NSString *telephonyPhoneType;
    @property (strong, nonatomic) NSString *telephonySignalStrength;
    @property (strong, nonatomic) NSString *telephonyNetworkOperator;
    @property (strong, nonatomic) NSString *telephonyNetworkOperatorName;
    @property (strong, nonatomic) NSString *timeStamp;

- (NSDictionary*) asDictionary;

@end
