////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

// Asynchronously submits build information to Realm if running in an iOS
// simulator or on OS X if a debugger is attached. Does nothing if running on an
// iOS / watchOS device or if a debugger is *not* attached.
//
// To be clear: this does *not* run when your app is in production or on
// your end-user’s devices; it will only run in the simulator or when a debugger
// is attached.
//
// Why are we doing this? In short, because it helps us build a better product
// for you. None of the data personally identifies you, your employer or your
// app, but it *will* help us understand what language you use, what iOS
// versions you target, etc. Having this info will help prioritizing our time,
// adding new features and deprecating old features. Collecting an anonymized
// bundle & anonymized MAC is the only way for us to count actual usage of the
// other metrics accurately. If we don’t have a way to deduplicate the info
// reported, it will be useless, as a single developer building their Swift app
// 10 times would report 10 times more than a single Objective-C developer that
// only builds once, making the data all but useless.
// No one likes sharing data unless it’s necessary, we get it, and we’ve
// debated adding this for a long long time. Since Realm is a free product
// without an email signup, we feel this is a necessary step so we can collect
// relevant data to build a better product for you. If you truly, absolutely
// feel compelled to not send this data back to Realm, then you can set an env
// variable named REALM_DISABLE_ANALYTICS. Since Realm is free we believe
// letting these analytics run is a small price to pay for the product & support
// we give you.
//
// Currently the following information is reported:
// - What version of Realm and core is being used, and from which language (obj-c or Swift).
// - Which platform and version of OS X it's running on (in case Xcode aggressively drops
//   support for older versions again, we need to know what we need to support).
// - The minimum iOS/OS X version that the application is targeting (again, to
//   help us decide what versions we need to support).
// - An anonymous MAC address and bundle ID to aggregate the other information on.
// - The host platform OSX and version.
// - The XCode version.
// - Some info about the features been used when opening the realm for the first time.

#import "RLMAnalytics.hpp"

#import <Foundation/Foundation.h>

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_MAC || (TARGET_OS_WATCH && TARGET_OS_SIMULATOR) || (TARGET_OS_TV && TARGET_OS_SIMULATOR)
#import "RLMObjectSchema_Private.h"
#import "RLMRealmConfiguration_Private.h"
#import "RLMSchema_Private.h"
#import "RLMSyncConfiguration.h"
#import "RLMUtil.hpp"

#import <array>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

#import <CommonCrypto/CommonDigest.h>

#ifndef REALM_COCOA_VERSION
#import "RLMVersion.h"
#endif

#ifndef REALM_IOPLATFORMUUID
#import <Realm/RLMPlatform.h>
#endif

// Wrapper for sysctl() that handles the memory management stuff
static auto RLMSysCtl(int *mib, u_int mibSize, size_t *bufferSize) {
    std::unique_ptr<void, decltype(&free)> buffer(nullptr, &free);

    int ret = sysctl(mib, mibSize, nullptr, bufferSize, nullptr, 0);
    if (ret != 0) {
        return buffer;
    }

    buffer.reset(malloc(*bufferSize));
    if (!buffer) {
        return buffer;
    }

    ret = sysctl(mib, mibSize, buffer.get(), bufferSize, nullptr, 0);
    if (ret != 0) {
        buffer.reset();
    }

    return buffer;
}

// Get the version of OS X we're running on (even in the simulator this gives
// the OS X version and not the simulated iOS version)
static NSString *RLMHostOSVersion() {
    size_t size;
    sysctlbyname("kern.osproductversion", NULL, &size, NULL, 0);
    char *model = (char*)malloc(size);
    sysctlbyname("kern.osproductversion", model, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    return deviceModel;
}

static NSString *RLMHostArch() {
    std::array<int, 2> mib = {{CTL_HW, HW_MACHINE}};
    size_t bufferSize;
    auto buffer = RLMSysCtl(&mib[0], mib.size(), &bufferSize);
    if (!buffer) {
        return nil;
    }

    NSString *n = [[NSString alloc] initWithBytesNoCopy:buffer.release()
                                                 length:bufferSize - 1
                                               encoding:NSUTF8StringEncoding
                                           freeWhenDone:YES];
    return n;
}

static NSString *RLMTargetArch() {
    NSString *targetArchitecture;
#if TARGET_CPU_X86
    targetArchitecture = @"x86";
#elif TARGET_CPU_X86_64
    targetArchitecture = @"x86_64";
#elif TARGET_CPU_ARM
    targetArchitecture = @"arm";
#elif TARGET_CPU_ARM64
    targetArchitecture = @"arm64";
#endif
    return targetArchitecture;
}

static NSString *RLMXCodeVersion() {
    NSString *xcodeVersion;
#if TARGET_OS_WATCH
#if __WATCH_OS_VERSION_MAX_ALLOWED >= 90200
    xcodeVersion = @"14.3";
// Because the max version allowed for XCode 14.2 and XCode 14.1 are the same, we are registering this as users of the latest version which is 14.2
#elif __WATCH_OS_VERSION_MAX_ALLOWED >= 90100
    xcodeVersion = @"14.2";
#elif __WATCH_OS_VERSION_MAX_ALLOWED >= 90000
    xcodeVersion = @"14.0.1";
#elif __WATCH_OS_VERSION_MAX_ALLOWED >= 80500
    xcodeVersion = @"13.4.1";
#endif
#elif TARGET_OS_TV
#if __TV_OS_VERSION_MAX_ALLOWED >= 160200
    xcodeVersion = @"14.3";
// Because the max version allowed for XCode 14.2 and XCode 14.1 are the same, we are registering this as users of the latest version which is 14.2
#elif __TV_OS_VERSION_MAX_ALLOWED >= 160100
    xcodeVersion = @"14.2";
#elif __TV_OS_VERSION_MAX_ALLOWED >= 160000
    xcodeVersion = @"14.0.1";
#elif __TV_OS_VERSION_MAX_ALLOWED >= 150400
    xcodeVersion = @"13.4.1";
#endif
#elif TARGET_OS_IPHONE
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160300
    xcodeVersion = @"14.3";
#elif __IPHONE_OS_VERSION_MAX_ALLOWED >= 160200
    xcodeVersion = @"14.2";
#elif __IPHONE_OS_VERSION_MAX_ALLOWED >= 160100
    xcodeVersion = @"14.1";
#elif __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
    xcodeVersion = @"14.0.1";
#elif __IPHONE_OS_VERSION_MAX_ALLOWED >= 150600
    xcodeVersion = @"13.4.1";
#endif
#else
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 130200
    xcodeVersion = @"14.3";
#elif __MAC_OS_X_VERSION_MAX_ALLOWED >= 130100
    xcodeVersion = @"14.2";
#elif __MAC_OS_X_VERSION_MAX_ALLOWED >= 130000
    xcodeVersion = @"14.1";
#elif __MAC_OS_X_VERSION_MAX_ALLOWED >= 120500
    xcodeVersion = @"14.0.1";
#elif __MAC_OS_X_VERSION_MAX_ALLOWED >= 120300
    xcodeVersion = @"13.4.1";
#endif
#endif
    return xcodeVersion;
}

// Hash the data in the given buffer and convert it to a hex-format string
static NSString *RLMHashBase16Data(const void *bytes, size_t length) {
    unsigned char buffer[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(bytes, static_cast<CC_LONG>(length), buffer);

    char formatted[CC_SHA256_DIGEST_LENGTH * 2 + 1];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        snprintf(formatted + i * 2, sizeof(formatted) - i * 2, "%02x", buffer[i]);
    }

    return [[NSString alloc] initWithBytes:formatted
                                    length:CC_SHA256_DIGEST_LENGTH * 2
                                  encoding:NSUTF8StringEncoding];
}

static std::optional<std::array<unsigned char, 6>> getMacAddress(int id) {
    char buff[] = "en0";
    snprintf(buff + 2, 2, "%d", id);
    int index = static_cast<int>(if_nametoindex(buff));
    if (!index) {
        return std::nullopt;
    }

    std::array<int, 6> mib = {{CTL_NET, PF_ROUTE, 0, AF_LINK, NET_RT_IFLIST, index}};
    size_t bufferSize;
    auto buffer = RLMSysCtl(&mib[0], mib.size(), &bufferSize);
    if (!buffer) {
        return std::nullopt;
    }

    // sockaddr_dl struct is immediately after the if_msghdr struct in the buffer
    auto sockaddr = reinterpret_cast<sockaddr_dl *>(static_cast<if_msghdr *>(buffer.get()) + 1);
    std::array<unsigned char, 6> mac;
    std::memcpy(&mac[0], sockaddr->sdl_data + sockaddr->sdl_nlen, 6);

    // Touch bar internal network interface, which is identical on all touch bar macs
    if (mac == std::array<unsigned char, 6>{0xAC, 0xDE, 0x48, 0x00, 0x11, 0x22}) {
        return std::nullopt;
    }

    // The mac address reported on iOS. It's unclear how we're seeing this as
    // this code doesn't run on iOS, but it somehow sometimes happens.
    if (mac == std::array<unsigned char, 6>{2, 0, 0, 0, 0, 0}) {
        return std::nullopt;
    }

    return mac;
}

// Returns the hash of the MAC address of the first network adaptor since the
// vendorIdentifier isn't constant between iOS simulators.
static NSString *RLMMACAddress() {
     for (int i = 0; i < 9; ++i) {
         if (auto mac = getMacAddress(i)) {
             return RLMHashBase16Data(&(*mac)[0], 6);
         }
     }
     return @"unknown";
 }

static NSString *RLMBuilderId() {
    NSString *iopPlatformUuid = REALM_IOPLATFORMUUID;
    NSString *salt = @"realm is great";

    NSString *saltedId = [iopPlatformUuid stringByAppendingString:salt];
    NSData *data = [saltedId dataUsingEncoding:NSUTF8StringEncoding];

    unsigned char buffer[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, static_cast<CC_LONG>(data.length), buffer);

    char formatted[CC_SHA256_DIGEST_LENGTH * 2 + 1];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        snprintf(formatted + i * 2, sizeof(formatted) - i * 2, "%02x", buffer[i]);
    }
    NSData* dataFormatted = [NSData dataWithBytes:formatted length:CC_SHA256_DIGEST_LENGTH * 2 + 1];

    // Base64 Encoding
    return [dataFormatted base64EncodedStringWithOptions:kNilOptions];
}

static NSDictionary *RLMBaseMetrics() {
    static NSString *kUnknownString = @"unknown";
    NSBundle *appBundle = NSBundle.mainBundle;
    NSString *hashedBundleID = appBundle.bundleIdentifier;

    // Main bundle isn't always the one of interest (e.g. when running tests
    // it's xctest rather than the app's bundle), so look for one with a bundle ID
    if (!hashedBundleID) {
        for (NSBundle *bundle in NSBundle.allBundles) {
            if ((hashedBundleID = bundle.bundleIdentifier)) {
                appBundle = bundle;
                break;
            }
        }
    }

    // If we found a bundle ID anywhere, hash it as it could contain sensitive
    // information (e.g. the name of an unannounced product)
    if (hashedBundleID) {
        NSData *data = [hashedBundleID dataUsingEncoding:NSUTF8StringEncoding];
        hashedBundleID = RLMHashBase16Data(data.bytes, data.length);
    }

    NSString *osVersionString = [[NSProcessInfo processInfo] operatingSystemVersionString];
    Class swiftUtil = NSClassFromString(@"RealmSwiftDecimal128");
    BOOL isSwift = swiftUtil != nil;

    NSString *hashedDistinctId = RLMMACAddress();
    NSString *hashedBuilderId = RLMBuilderId();

    NSDictionary *info = appBundle.infoDictionary;

    BOOL isClang = __clang__ == 1;

    return @{
        // MixPanel properties
        @"token": @"ce0fac19508f6c8f20066d345d360fd0",

        // Anonymous identifiers to deduplicate events
        @"distinct_id": hashedDistinctId,
        @"builder_id": hashedBuilderId,

        @"Anonymized MAC Address": hashedDistinctId,
        @"Anonymized Bundle ID": hashedBundleID ?: kUnknownString,

        // SDK Info
        @"Binding": @"cocoa",
        // Which version of Realm is being used
        @"Realm Version": REALM_COCOA_VERSION,
        @"Core Version": @REALM_VERSION,

        // Language Info
        @"Language": isSwift ? @"swift" : @"objc",

        // Target Info
        // Current OS version the app is targeting
        @"Target OS Version": osVersionString,
        // Minimum OS version the app is targeting
        @"Target OS Minimum Version": info[@"MinimumOSVersion"] ?: info[@"LSMinimumSystemVersion"] ?: kUnknownString,
#if TARGET_OS_WATCH
        @"Target OS Type": @"watchos",
#elif TARGET_OS_TV
        @"Target OS Type": @"tvos",
#elif TARGET_OS_IPHONE
        @"Target OS Type": @"ios",
#else
        @"Target OS Type": @"macos",
#endif
        @"Target CPU Arch": RLMTargetArch() ?: kUnknownString,

        // Framework
#if TARGET_OS_MACCATALYST
        @"Framework": @"maccatalyst",
#endif

        // Host Info
        // Host OS version being built on
        @"Host OS Type": @"macos",
        @"Host OS Version": RLMHostOSVersion() ?: kUnknownString,
        // Architecture
        @"Host CPU Arch": RLMHostArch() ?: kUnknownString,

        // Installation method
#ifdef SWIFT_PACKAGE
        @"Installation Method": @"spm",
#elif defined(COCOAPODS)
        @"Installation Method": @"cocoapods",
#elif defined(CARTHAGE)
        @"Installation Method": @"carthage",
#elif defined(REALM_IOS_STATIC)
        @"Installation Method": @"static framework",
#else
        @"Installation Method": @"other",
#endif

        // Compiler Info
        @"Compiler": isClang ? @"clang" : @"other",
        @"Clang Version": @__clang_version__,
        @"Clang Major Version": @__clang_major__,

        // This will report the XCode Version even if the developer is using another
        // IDE(AppCode), in that case this will register the version of the XCode tools
        // AppCode is using.
        @"IDE Version": RLMXCodeVersion() ?: kUnknownString,
    };
}

// This will only be executed once but depending on the number of objects, could take sometime
static NSDictionary *RLMSchemaMetrics(RLMSchema *schema) {
    NSDictionary *dict = @{
        @"Embedded_Object": @0,
        @"Asymmetric_Object": @0,
        @"Reference_Link": @0,
        @"Mixed": @0,
        @"Primitive_List": @0,
        @"Primitive_Set": @0,
        @"Primitive_Dictionary": @0,
        @"Reference_List": @0,
        @"Reference_Set": @0,
        @"Reference_Dictionary": @0,
    };
    NSMutableDictionary *featuresDictionary = [[NSMutableDictionary alloc] init];
    [featuresDictionary addEntriesFromDictionary: dict];
    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        if (objectSchema.isEmbedded) {
            [featuresDictionary setObject:@1 forKey:@"Embedded_Object"];
        }
        if (objectSchema.isAsymmetric) {
            [featuresDictionary setObject:@1 forKey:@"Asymmetric_Object"];
        }

        for (RLMProperty *property in objectSchema.properties) {
            if (property.array) {
                if (property.type == RLMPropertyTypeObject) {
                    [featuresDictionary setObject:@1 forKey:@"Reference_List"];
                } else {
                    [featuresDictionary setObject:@1 forKey:@"Primitive_List"];
                }
                continue;
            }
            if (property.set) {
                if (property.type == RLMPropertyTypeObject) {
                    [featuresDictionary setObject:@1 forKey:@"Reference_Set"];
                } else {
                    [featuresDictionary setObject:@1 forKey:@"Primitive_Set"];
                }
                continue;
            }
            if (property.dictionary) {
                if (property.type == RLMPropertyTypeObject) {
                    [featuresDictionary setObject:@1 forKey:@"Reference_Dictionary"];
                } else {
                    [featuresDictionary setObject:@1 forKey:@"Primitive_Dictionary"];
                }
                continue;
            }

            switch (property.type) {
               case RLMPropertyTypeAny:
                    [featuresDictionary setObject:@1 forKey:@"Mixed"];
                  break;
               case RLMPropertyTypeObject:
                    [featuresDictionary setObject:@1 forKey:@"Reference_Link"];
                  break;
                case RLMPropertyTypeLinkingObjects:
                     [featuresDictionary setObject:@1 forKey:@"Backlink"];
                   break;
               default:
                    break;
            }
        }
    }
    return featuresDictionary;
}

static NSDictionary *RLMConfigurationMetrics(RLMRealmConfiguration *configuration) {
    BOOL isSyncEnable = configuration.syncConfiguration != nil;
    BOOL isSync = configuration.syncConfiguration != nil;
    BOOL isPBSSync = configuration.syncConfiguration.partitionValue != nil;
    BOOL isFlexibleSync = (isSync && !isPBSSync);
    BOOL isCompactOnLaunch = configuration.shouldCompactOnLaunch != nil;
    BOOL migrationBlock = configuration.migrationBlock != nil;

    auto resetMode = configuration.syncConfiguration.clientResetMode;
    return @{
        // Sync
        @"Sync Enabled": isSyncEnable ? @"true" : @"false",
        @"Flexible_Sync": isFlexibleSync ? @1 : @0,
        @"Pbs_Sync": isPBSSync ? @1 : @0,

        // Client Reset
        @"Client_Reset_Recover_Or_Discard": (isSync && resetMode == RLMClientResetModeRecoverOrDiscardUnsyncedChanges) ? @1 : @0,
        @"Client_Reset_Recover": (isSync && resetMode == RLMClientResetModeRecoverUnsyncedChanges) ? @1 : @0,
        @"Client_Reset_Discard": (isSync && resetMode == RLMClientResetModeDiscardUnsyncedChanges) ? @1 : @0,
        @"Client_Reset_Manual": (isSync && resetMode == RLMClientResetModeManual) ? @1 : @0,

        // Configuration
        @"Compact_On_Launch": isCompactOnLaunch ? @1 : @0,
        @"Schema_Migration_Block": migrationBlock ? @1 : @0,
    };
}

void RLMSendAnalytics(RLMRealmConfiguration *configuration, RLMSchema *schema) {
    if (getenv("REALM_DISABLE_ANALYTICS") || !RLMIsDebuggerAttached() || RLMIsRunningInPlayground()) {
        return;
    }
    NSArray *urlStrings = @[@"https://data.mongodb-api.com/app/realmsdkmetrics-zmhtm/endpoint/metric_webhook/metric?data=%@"];

    NSDictionary *baseMetrics = RLMBaseMetrics();
    NSDictionary *schemaMetrics = RLMSchemaMetrics(schema);
    NSDictionary *configurationMetrics = RLMConfigurationMetrics(configuration);

    NSMutableDictionary *metrics = [[NSMutableDictionary alloc] init];
    [metrics addEntriesFromDictionary:baseMetrics];
    [metrics addEntriesFromDictionary:schemaMetrics];
    [metrics addEntriesFromDictionary:configurationMetrics];

    NSMutableDictionary *payloadN = [NSMutableDictionary dictionaryWithDictionary:@{ @"event": @"Run" }];
    [payloadN setObject:metrics forKey:@"properties"];
    NSData *payload = [NSJSONSerialization dataWithJSONObject:payloadN options:0 error:nil];

    for (NSString *urlString in urlStrings) {
        NSString *formatted = [NSString stringWithFormat:urlString, [payload base64EncodedStringWithOptions:0]];
        // No error handling or anything because logging errors annoyed people for no
        // real benefit, and it's not clear what else we could do
        [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:formatted]] resume];
    }
}

#else

void RLMSendAnalytics() {}

#endif
