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

static NSString *RLMTargetArch() {
    NSString *targetArchitecture;
#if TARGET_CPU_X86_64
    targetArchitecture = @"x86_64";
#elif TARGET_CPU_ARM64
    targetArchitecture = @"arm64";
#endif
    return targetArchitecture;
}

// Hash the data in the given buffer and convert it to a hex-format string
NSString *RLMHashBase16Data(const void *bytes, size_t length) {
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
#ifdef REALM_IOPLATFORMUUID
    NSString *saltedId = [@"Realm is great" stringByAppendingString:REALM_IOPLATFORMUUID];
    NSData *data = [saltedId dataUsingEncoding:NSUTF8StringEncoding];

    unsigned char buffer[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, static_cast<CC_LONG>(data.length), buffer);
    NSData* hashedData = [NSData dataWithBytes:buffer length:CC_SHA256_DIGEST_LENGTH];
    
    // Base64 Encoding
    return [hashedData base64EncodedStringWithOptions:kNilOptions];
#else
    return nil;
#endif
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

    Class swiftDecimal128 = NSClassFromString(@"RealmSwiftDecimal128");
    BOOL isSwift = swiftDecimal128 != nil;

    NSString *hashedDistinctId = RLMMACAddress();
    // We use the IOPlatformUUID if is available (Cocoapods, SPM),
    // in case we cannot obtain it (Pre-built binaries) we use the hashed mac address.
    NSString *hashedBuilderId = RLMBuilderId() ?: hashedDistinctId;

    NSDictionary *info = appBundle.infoDictionary;

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
        @"Target OS Version": [[NSProcessInfo processInfo] operatingSystemVersionString],
        // Minimum OS version the app is targeting
        @"Target OS Minimum Version": info[@"MinimumOSVersion"] ?: info[@"LSMinimumSystemVersion"] ?: kUnknownString,
#if defined(TARGET_OS_VISION) && TARGET_OS_VISION // TARGET_OS_VISION first defined in Xcode 15.2
        @"Target OS Type": @"visionos",
#elif TARGET_OS_WATCH
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
        @"Compiler": @"clang",
        @"Clang Version": @__clang_version__,
        @"Clang Major Version": @__clang_major__,
    };
}

// This will only be executed once but depending on the number of objects, could take sometime
static NSDictionary *RLMSchemaMetrics(RLMSchema *schema) {
    NSMutableDictionary *featuresDictionary = [@{@"Embedded_Object": @0,
                                                 @"Asymmetric_Object": @0,
                                                 @"Object_Link": @0,
                                                 @"Mixed": @0,
                                                 @"Primitive_List": @0,
                                                 @"Primitive_Set": @0,
                                                 @"Primitive_Dictionary": @0,
                                                 @"Object_List": @0,
                                                 @"Object_Set": @0,
                                                 @"Object_Dictionary": @0,
                                                 @"Backlink": @0,
                                               } mutableCopy];

    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        if (objectSchema.isEmbedded) {
            featuresDictionary[@"Embedded_Object"] = @1;
        }
        if (objectSchema.isAsymmetric) {
            featuresDictionary[@"Asymmetric_Object"] = @1;
        }

        for (RLMProperty *property in objectSchema.properties) {
            if (property.array) {
                if (property.type == RLMPropertyTypeObject) {
                    featuresDictionary[@"Object_List"] = @1;
                } else {
                    featuresDictionary[@"Primitive_List"] = @1;
                }
                continue;
            }
            if (property.set) {
                if (property.type == RLMPropertyTypeObject) {
                    featuresDictionary[@"Object_Set"] = @1;
                } else {
                    featuresDictionary[@"Primitive_Set"] = @1;
                }
                continue;
            }
            if (property.dictionary) {
                if (property.type == RLMPropertyTypeObject) {
                    featuresDictionary[@"Object_Dictionary"] = @1;
                } else {
                    featuresDictionary[@"Primitive_Dictionary"] = @1;
                }
                continue;
            }

            switch (property.type) {
               case RLMPropertyTypeAny:
                    featuresDictionary[@"Mixed"] = @1;
                  break;
               case RLMPropertyTypeObject:
                    featuresDictionary[@"Object_Link"] = @1;
                  break;
                case RLMPropertyTypeLinkingObjects:
                    featuresDictionary[@"Backlink"] = @1;
                   break;
               default:
                    break;
            }
        }
    }
    return featuresDictionary;
}

static NSDictionary *RLMConfigurationMetrics(RLMRealmConfiguration *configuration) {
    RLMSyncConfiguration *syncConfiguration = configuration.syncConfiguration;
    bool isSync = syncConfiguration != nil;
    bool isPBSSync = syncConfiguration.partitionValue != nil;
    bool isFlexibleSync = (isSync && !isPBSSync);
    auto resetMode = syncConfiguration.clientResetMode;

    bool isCompactOnLaunch = configuration.shouldCompactOnLaunch != nil;
    bool migrationBlock = configuration.migrationBlock != nil;

    return @{
        // Sync
        @"Sync Enabled": isSync ? @"true" : @"false",
        @"Flx_Sync": isFlexibleSync ? @1 : @0,
        @"Pbs_Sync": isPBSSync ? @1 : @0,

        // Client Reset
        @"CR_Recover_Discard": (isSync && resetMode == RLMClientResetModeRecoverOrDiscardUnsyncedChanges) ? @1 : @0,
        @"CR_Recover": (isSync && resetMode == RLMClientResetModeRecoverUnsyncedChanges) ? @1 : @0,
        @"CR_Discard": (isSync && resetMode == RLMClientResetModeDiscardUnsyncedChanges) ? @1 : @0,
        @"CR_Manual": (isSync && resetMode == RLMClientResetModeManual) ? @1 : @0,

        // Configuration
        @"Compact_On_Launch": isCompactOnLaunch ? @1 : @0,
        @"Schema_Migration_Block": migrationBlock ? @1 : @0,
    };
}

void RLMSendAnalytics(RLMRealmConfiguration *configuration, RLMSchema *schema) {
    if (getenv("REALM_DISABLE_ANALYTICS") || !RLMIsDebuggerAttached() || RLMIsRunningInPlayground()) {
        return;
    }

    id config = [configuration copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *baseMetrics = RLMBaseMetrics();
        NSDictionary *schemaMetrics = RLMSchemaMetrics(schema);
        NSDictionary *configurationMetrics = RLMConfigurationMetrics(config);

        NSMutableDictionary *metrics = [[NSMutableDictionary alloc] init];
        [metrics addEntriesFromDictionary:baseMetrics];
        [metrics addEntriesFromDictionary:schemaMetrics];
        [metrics addEntriesFromDictionary:configurationMetrics];

        NSDictionary *payloadN = @{@"event": @"Run", @"properties": metrics};
        NSData *payload = [NSJSONSerialization dataWithJSONObject:payloadN options:0 error:nil];

        NSString *url = @"https://data.mongodb-api.com/app/realmsdkmetrics-zmhtm/endpoint/metric_webhook/metric?data=%@";
        NSString *formatted = [NSString stringWithFormat:url, [payload base64EncodedStringWithOptions:0]];
        // No error handling or anything because logging errors annoyed people for no
        // real benefit, and it's not clear what else we could do
        [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:formatted]] resume];
    });
}

#else

void RLMSendAnalytics() {}

#endif
