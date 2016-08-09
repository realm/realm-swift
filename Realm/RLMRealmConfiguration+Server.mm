////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMRealmConfiguration+Server.h"

#import "RLMRealmConfiguration_Private.hpp"

#import "RLMUser_Private.h"
#import "RLMServerUtil_Private.h"
#import "RLMUtil.hpp"

typedef void(^RLMInternalLoginBlock)(const std::string&);

@implementation RLMRealmConfiguration (Server)

/**
 The directory within which all Realm Object Server related Realm database and support files are stored. This directory
 is a subdirectory within the default directory within which normal on-disk Realms are stored.

 The directory will be created if it does not already exist, and then verified. If there was an error setting it up an
 exception will be thrown.
 */
+(NSURL *)baseDirectory {
    static NSURL *s_baseDirectory;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Create the path.
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *base = [NSURL fileURLWithPath:RLMDefaultDirectoryForBundleIdentifier(nil)];
        s_baseDirectory = [base URLByAppendingPathComponent:@".realm-object-server" isDirectory:YES];

        // If the directory does not already exist, create it.
        [manager createDirectoryAtURL:s_baseDirectory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        BOOL isDirectory;
        BOOL fileExists = [manager fileExistsAtPath:[s_baseDirectory path] isDirectory:&isDirectory];
        if (!fileExists || !isDirectory) {
            @throw RLMException(@"Realm was not able to prepare its directory for storing server-synchronized Realm files.");
        }
    });
    return s_baseDirectory;
}

+(NSURL *)filePathForObjectServerURL:(NSURL *)serverURL user:(RLMUser *)user {
    NSString *userID = user.identity;
    if (!userID) {
        @throw RLMException(@"Realm cannot open local disk files for users configured without a user ID.");
        return nil;
    }

    NSCharacterSet *alpha = [NSCharacterSet alphanumericCharacterSet];
    NSString *escapedPath = [[serverURL path] stringByAddingPercentEncodingWithAllowedCharacters:alpha];
    NSString *escapedUserID = [userID stringByAddingPercentEncodingWithAllowedCharacters:alpha];
    NSString *escapedHost = [[serverURL host] stringByAddingPercentEncodingWithAllowedCharacters:alpha];
    NSString *realmFileName = [NSString stringWithFormat:@"%@-%@-%@.realm", escapedHost, escapedPath, escapedUserID];
    return [[self baseDirectory] URLByAppendingPathComponent:realmFileName];
}

- (void)setErrorHandler:(RLMErrorReportingBlock)errorHandler {
    RLMErrorReportingBlock callback = (errorHandler ?: ^(NSError *) { });

    auto handler = [=](int error_code, std::string message) {
        NSString *nativeMessage = @(message.c_str());
        NSError *error = [NSError errorWithDomain:RLMServerErrorDomain
                                             code:RLMServerInternalError
                                         userInfo:@{@"description": nativeMessage,
                                                    @"error": @(error_code)}];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(error);
        });
    };
    self.config.sync_error_handler = handler;
}

- (void)setObjectServerPath:(RLMServerPath)path
                    forUser:(RLMUser *)user {
    [self setObjectServerPath:path forUser:user callback:nil];
}

- (void)setObjectServerPath:(RLMServerPath)path
                    forUser:(RLMUser *)user
                   callback:(nullable RLMErrorReportingBlock)callback {
    if (!path) {
        // Clear the object server state. User must explicitly set a file URL or in-memory identifier.
        self.config.sync_user_id = realm::util::none;
        self.config.sync_login_function = nullptr;
        self.fileURL = nil;
        self.inMemoryIdentifier = nil;
        return;
    }
    if (!user) {
        @throw RLMException(@"If an Realm Object Server path is being set on a configuration, a valid user must also be specified.");
    }
    if (!user.isLoggedIn) {
        @throw RLMException(@"A configuration may only be configured with a logged-in user.");
    }
    // Set the Realm Object Server URL and associated state
    NSURL *objectServerURL = [NSURL URLWithString:path relativeToURL:user.objectServerURL];
    self.config.sync_user_id = std::string([user.identity UTF8String]);
    self.config.sync_login_function = [user, objectServerURL, callback](const std::string& fileURL) {
        [user _bindRealmWithLocalFileURL:fileURL remoteServerURL:objectServerURL onCompletion:callback];
    };

    // Set the file URL
    NSURL *fileURL = [RLMRealmConfiguration filePathForObjectServerURL:objectServerURL user:user];
    self.config.path = [[fileURL path] UTF8String];
    self.config.in_memory = false;
}

@end
