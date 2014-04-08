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

#import <objc/runtime.h>
#import "TDBCrashReportingAgentLauncher.h"

// the apigee crash reporter only works on arm
#if defined(__arm__) || defined(__arm64__)
#import "Apigee.h"

// org and app name identifiers for Apigee service
static NSString* kApigeeOrgName             = @"slipjack";
static NSString* kApigeeAppName             = @"testapp";

// boolean property that can be set in Info.plist to disable crash reporting
static NSString* kPropDisableCrashReporting = @"TDBDisableCrashReporting";

// key to use for attaching (dynamically) to application delegate at runtime
static char const * const keyCrashReportingAgent = "crashAgentKey";
#endif



@implementation TDBCrashReportingAgentLauncher

- (void)startCrashReporter
{
// the apigee crash reporter only works on arm
#if defined(__arm__) || defined(__arm64__)
    // has crash reporting been disabled by the app developer?
    id propCrashReporting =
        [[NSBundle mainBundle].infoDictionary objectForKey:kPropDisableCrashReporting];
      
    if (propCrashReporting) {
        if ([propCrashReporting isKindOfClass:[NSNumber class]]) {
            NSNumber* propCrashReportingAsNumber = (NSNumber*) propCrashReporting;
            const BOOL isCrashReportingDisabled =
                [propCrashReportingAsNumber boolValue];
            if (isCrashReportingDisabled) {
                NSLog(@"TightDB crash reporting disabled");
                return;
            }
        }
    }
   
    ApigeeMonitoringOptions* monitoringOptions =
        [[ApigeeMonitoringOptions alloc] init];
    monitoringOptions.autoPromoteLoggedErrors = NO;
    monitoringOptions.interceptNSURLSessionCalls = NO;
    monitoringOptions.crashReportingEnabled = YES;
   
    ApigeeClient* apigeeClient = [[ApigeeClient alloc]
                                    initWithOrganizationId:kApigeeOrgName
                                             applicationId:kApigeeAppName
                                                   baseURL:nil
                                                   options:monitoringOptions];
                                                   
    if (apigeeClient) {
        // the following code is doing the same thing as this (dynamically) to avoid
        // having direct dependencies on UIKit.
        //       id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
        //
        Class clsUIApplication = NSClassFromString(@"UIApplication");
        if (clsUIApplication) {
            if ([clsUIApplication respondsToSelector:@selector(sharedApplication)]) {
                id uiApplication = [clsUIApplication performSelector:@selector(sharedApplication)];
                if (uiApplication) {
                    if ([uiApplication respondsToSelector:@selector(delegate)]) {
                        id appDelegate = [uiApplication performSelector:@selector(delegate)];
                        if (appDelegate) {
                            // attach the crash reporter agent to the app delegate so that we don't
                            // have to worry about it disappearing on us while the app is running
                            // and so that we can get a reference to it if needed.
                            objc_setAssociatedObject(appDelegate,
                                                     keyCrashReportingAgent,
                                                     apigeeClient,
                                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      
                            NSLog(@"crash reporter initialized and active");
                        }
                    }
                }
            }
        }
    } else {
        NSLog(@"error: unable to initialize crash reporter");
    }
#endif
}

@end
