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

#import "TestUtils.h"
#import "RLMAssertions.h"

#import <Realm/Realm.h>
#import <Realm/RLMSchema_Private.h>

#import "RLMRealmUtil.hpp"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncManager_Private.hpp"

#import <realm/object-store/impl/apple/keychain_helper.hpp>
#import <realm/object-store/sync/impl/sync_file.hpp>
#import <realm/object-store/sync/impl/sync_metadata.hpp>
#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/util/base64.hpp>

#import <Availability.h>

static void recordFailure(XCTestCase *self, NSString *message, NSString *fileName, NSUInteger lineNumber) {
#ifndef __MAC_10_16
    [self recordFailureWithDescription:message inFile:fileName atLine:lineNumber expected:NO];
#else
    XCTSourceCodeLocation *loc = [[XCTSourceCodeLocation alloc] initWithFilePath:fileName lineNumber:lineNumber];
    XCTIssue *issue = [[XCTIssue alloc] initWithType:XCTIssueTypeAssertionFailure
                                  compactDescription:message
                                 detailedDescription:nil
                                   sourceCodeContext:[[XCTSourceCodeContext alloc] initWithLocation:loc]
                                     associatedError:nil
                                         attachments:@[]];
    [self recordIssue:issue];
#endif
}

void RLMAssertThrowsWithReasonMatchingSwift(XCTestCase *self,
                                            __attribute__((noescape)) dispatch_block_t block,
                                            NSString *regexString, NSString *message,
                                            NSString *fileName, NSUInteger lineNumber) {
    BOOL didThrow = NO;
    @try {
        block();
    }
    @catch (NSException *e) {
        didThrow = YES;
        NSString *reason = e.reason;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:(NSRegularExpressionOptions)0 error:nil];
        if ([regex numberOfMatchesInString:reason options:(NSMatchingOptions)0 range:NSMakeRange(0, reason.length)] == 0) {
            NSString *msg = [NSString stringWithFormat:@"The given expression threw an exception with reason '%@', but expected to match '%@'",
                             reason, regexString];
            recordFailure(self, msg, fileName, lineNumber);
        }
    }
    if (!didThrow) {
        NSString *prefix = @"The given expression failed to throw an exception";
        message = message ? [NSString stringWithFormat:@"%@ (%@)",  prefix, message] : prefix;
        recordFailure(self, message, fileName, lineNumber);
    }
}

static void assertThrows(XCTestCase *self, dispatch_block_t block, NSString *message,
                         NSString *fileName, NSUInteger lineNumber,
                         NSString *(^condition)(NSException *)) {
    @try {
        block();
        NSString *prefix = @"The given expression failed to throw an exception";
        message = message ? [NSString stringWithFormat:@"%@ (%@)",  prefix, message] : prefix;
        recordFailure(self, message, fileName, lineNumber);
    }
    @catch (NSException *e) {
        if (NSString *failure = condition(e)) {
            recordFailure(self, failure, fileName, lineNumber);
        }
    }
}

void (RLMAssertThrowsWithName)(XCTestCase *self, __attribute__((noescape)) dispatch_block_t block,
                               NSString *name, NSString *message, NSString *fileName, NSUInteger lineNumber) {
    assertThrows(self, block, message, fileName, lineNumber, ^NSString *(NSException *e) {
        if ([name isEqualToString:e.name]) {
            return nil;
        }
        return [NSString stringWithFormat:@"The given expression threw an exception named '%@', but expected '%@'",
                             e.name, name];
    });
}

void (RLMAssertThrowsWithReason)(XCTestCase *self, __attribute__((noescape)) dispatch_block_t block,
                                 NSString *expected, NSString *message, NSString *fileName, NSUInteger lineNumber) {
    assertThrows(self, block, message, fileName, lineNumber, ^NSString *(NSException *e) {
        if ([e.reason rangeOfString:expected].location != NSNotFound) {
            return nil;
        }
        return [NSString stringWithFormat:@"The given expression threw an exception with reason '%@', but expected '%@'",
                             e.reason, expected];
    });
}

void (RLMAssertThrowsWithReasonMatching)(XCTestCase *self, __attribute__((noescape)) dispatch_block_t block,
                                         NSString *regexString, NSString *message,
                                         NSString *fileName, NSUInteger lineNumber) {
    auto regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                           options:(NSRegularExpressionOptions)0 error:nil];
    assertThrows(self, block, message, fileName, lineNumber, ^NSString *(NSException *e) {
        if ([regex numberOfMatchesInString:e.reason options:(NSMatchingOptions)0 range:{0, e.reason.length}] > 0) {
            return nil;
        }
        return [NSString stringWithFormat:@"The given expression threw an exception with reason '%@', but expected to match '%@'",
                             e.reason, regexString];
    });
}


void (RLMAssertMatches)(XCTestCase *self, __attribute__((noescape)) NSString *(^block)(),
                        NSString *regexString, NSString *message, NSString *fileName, NSUInteger lineNumber) {
    NSString *result = block();
    NSError *err;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:(NSRegularExpressionOptions)0 error:&err];
    if (err) {
        recordFailure(self, err.localizedDescription, fileName, lineNumber);
        return;
    }
    if ([regex numberOfMatchesInString:result options:(NSMatchingOptions)0 range:NSMakeRange(0, result.length)] == 0) {
        NSString *msg = [NSString stringWithFormat:@"The given expression '%@' did not match '%@'%@",
                         result, regexString, message ? [NSString stringWithFormat:@": %@", message] : @""];
        recordFailure(self, msg, fileName, lineNumber);
    }
}

void (RLMAssertExceptionReason)(XCTestCase *self,
                                NSException *exception, NSString *expected, NSString *expression,
                                NSString *fileName, NSUInteger lineNumber) {
    if (!exception) {
        return;
    }
    if ([exception.reason rangeOfString:(expected)].location != NSNotFound) {
        return;
    }

    auto location = [[XCTSourceCodeContext alloc] initWithLocation:[[XCTSourceCodeLocation alloc] initWithFilePath:fileName lineNumber:lineNumber]];
    NSString *desc = [NSString stringWithFormat:@"The expression %@ threw an exception with reason '%@', but expected to contain '%@'", expression, exception.reason ?: @"<nil>", expected];
    auto issue = [[XCTIssue alloc] initWithType:XCTIssueTypeAssertionFailure
                             compactDescription:desc
                            detailedDescription:nil
                              sourceCodeContext:location
                                associatedError:nil
                                    attachments:@[]];
    [self recordIssue:issue];
}

bool RLMHasCachedRealmForPath(NSString *path) {
    return RLMGetAnyCachedRealmForPath(path.UTF8String);
}

static std::string serialize(id obj) {
    auto data = [NSJSONSerialization dataWithJSONObject:obj
                                                options:0
                                                  error:nil];
    return std::string(static_cast<const char *>(data.bytes), data.length);
}

static std::string fakeJWT() {
    std::string unencoded_prefix = serialize(@{@"alg": @"HS256"});
    std::string unencoded_body = serialize(@{
        @"user_data": @{@"token": @"dummy token"},
        @"exp": @123,
        @"iat": @456,
        @"access": @[@"download", @"upload"]
    });
    std::string encoded_prefix, encoded_body;
    encoded_prefix.resize(realm::util::base64_encoded_size(unencoded_prefix.size()));
    encoded_body.resize(realm::util::base64_encoded_size(unencoded_body.size()));
    realm::util::base64_encode(unencoded_prefix.data(), unencoded_prefix.size(),
                               &encoded_prefix[0], encoded_prefix.size());
    realm::util::base64_encode(unencoded_body.data(), unencoded_body.size(),
                               &encoded_body[0], encoded_body.size());
    std::string suffix = "Et9HFtf9R3GEMA0IICOfFMVXY7kkTX1wr4qCyhIf58U";
    return encoded_prefix + "." + encoded_body + "." + suffix;
}

RLMUser *RLMDummyUser() {
    // Add a fake user to the metadata Realm
    @autoreleasepool {
        auto config = [RLMSyncManager configurationWithRootDirectory:nil appId:@"dummy"];
        realm::SyncFileManager sfm(config.base_file_path, "dummy");
        realm::util::Optional<std::vector<char>> encryption_key;
        if (config.metadata_mode == realm::SyncClientConfig::MetadataMode::Encryption) {
            encryption_key = realm::keychain::get_existing_metadata_realm_key();
        }
        realm::SyncMetadataManager metadata_manager(sfm.metadata_path(),
                                                    encryption_key != realm::util::none,
                                                    encryption_key);
        auto user = metadata_manager.get_or_make_user_metadata("dummy", "https://example.invalid");
        auto token = fakeJWT();
        user->set_access_token(token);
        user->set_refresh_token(token);
    }

    // Creating an app reads the fake cached user
    RLMApp *app = [RLMApp appWithId:@"dummy"];
    return app.allUsers.allValues.firstObject;
}

// Xcode 13 adds -[NSUUID compare:] so this warns about the category
// implementing a method which already exists, but we can't use just the
// built-in one yet.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation NSUUID (RLMUUIDCompareTests)
- (NSComparisonResult)compare:(NSUUID *)other {
    return [[self UUIDString] compare:other.UUIDString];
}
@end
#pragma clang diagnostic pop

bool RLMThreadSanitizerEnabled() {
#if __has_feature(thread_sanitizer)
    return true;
#else
    return false;
#endif
}
