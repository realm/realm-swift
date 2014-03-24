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
#import <UIKit/UIKit.h>
#import "TDBContext+CrashReporting.h"


#define TIGHTDB_CRASH_REPORTING_ENABLED 1


//*********************************************************************************
// NOTE: when crash reporting is enabled (TIGHTDB_CRASH_REPORTING_ENABLED defined),
// this source file is compiled with dependencies on a modified (forked) version
// Apigee's iOS SDK. The forked version used by this source can be found at
// https://github.com/pauldardeau/apigee-ios-sdk. To build from source, run
// build.sh and then the static lib files and headers can be found in
// source/build/dist subdirectory.
//*********************************************************************************


#ifdef TIGHTDB_CRASH_REPORTING_ENABLED
#import "Apigee.h"

static char const * const keyCrashReportingAgent = "crashAgentKey";

static NSString* kPropDisableCrashReporting = @"TDBDisableCrashReporting";


// This class is used to launch Apigee's iOS agent. The intent is to make use
// of it for crash reporting.
@interface CrashReportingAgentLauncher : NSObject

@end


static CrashReportingAgentLauncher* agentLauncher = nil;


@implementation CrashReportingAgentLauncher

// This method will be called when the app has launched
- (void)handleAppBecomeActive
{
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
   
   // Apigee orgName/appName (change as necessary)
   NSString* orgName = @"slipjack";
   NSString* appName = @"testapp";
   
   // remove ourself from notification center
   NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
   [notifyCenter removeObserver:self
                           name:UIApplicationDidFinishLaunchingNotification
                        object:nil];
   
   ApigeeMonitoringOptions* monitoringOptions =
      [[ApigeeMonitoringOptions alloc] init];
   monitoringOptions.autoPromoteLoggedErrors = NO;
   monitoringOptions.interceptNSURLSessionCalls = NO;
   monitoringOptions.crashReportingEnabled = YES;
   
   ApigeeClient* apigeeClient = [[ApigeeClient alloc]
                   initWithOrganizationId:orgName
                   applicationId:appName
                   baseURL:nil
                   options:monitoringOptions];
   if (apigeeClient) {
      id<UIApplicationDelegate> appDelegate =
         [[UIApplication sharedApplication] delegate];
      
      if (appDelegate) {
         // attach the crash reporter agent to the app delegate so that we don't
         // have to worry about it disappearing on us while the app is running
         // and so that we can get a reference to it if needed.
         objc_setAssociatedObject(appDelegate,
                                  keyCrashReportingAgent,
                                  apigeeClient,
                                  OBJC_ASSOCIATION_RETAIN_NONATOMIC);
         
         // since we'll be funneling a bunch of totally different applications
         // into the same bucket of data, we'll track the bundle identifier
         // (normally of the form 'com.acme.mygreatapp') to help identify which
         // application and/or company is associated with particular crash
         // reports.
         NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
         if (bundleIdentifier) {
            ApigeeLogInfoMessage(@"APP", bundleIdentifier);
         }
      
         NSLog(@"crash reporter initialized and active");
      
         agentLauncher = nil;
      } else {
         NSLog(@"error: app delegate is nil");
      }
      
   } else {
      NSLog(@"error: unable to initialize crash reporter");
   }
}

@end

#endif



@implementation TDBContext (CrashReporting)

// This method is called automatically by the Objective-C runtime when the
// class is loaded (see docs for NSObject for details). This gives us a
// convenient mechanism to intercept initialization and start the crash reporter.
+ (void)load
{
#ifdef TIGHTDB_CRASH_REPORTING_ENABLED
   static dispatch_once_t once;
   
   dispatch_once(&once, ^{
      // This is a bit too early in the app loading process to start the
      // crash reporter, so we make use of a helper class
      // (CrashReportingAgentLauncher) that will be notified when the
      // app gets the 'didFinishLaunching'.
      agentLauncher = [[CrashReportingAgentLauncher alloc] init];
      [[NSNotificationCenter defaultCenter] addObserver:agentLauncher
                                               selector:@selector(handleAppBecomeActive)
                                                   name:UIApplicationDidFinishLaunchingNotification
                                                object :nil];
   });
#endif
}

@end
