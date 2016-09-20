////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

@interface RLMObjectServerTestCase : XCTestCase
@property (nonatomic, strong) NSTask *task;
@end

@implementation RLMObjectServerTestCase

+ (NSString *)rootRealmCocoaPath {
    return [[[[[NSURL fileURLWithPath:@(__FILE__)] URLByDeletingLastPathComponent] URLByDeletingLastPathComponent] URLByDeletingLastPathComponent] path];
}

- (void)setUp {
    [super setUp];
    self.task = [[NSTask alloc] init];
    self.task.currentDirectoryPath = [RLMObjectServerTestCase rootRealmCocoaPath];
    self.task.launchPath = @"/bin/sh";
    self.task.arguments = @[@"build.sh", @"start-object-server"];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    self.task.standardOutput = [NSPipe pipe];
    [[self.task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([output containsString:@"Received: IDENT"]) {
            dispatch_semaphore_signal(sema);
        }
    }];
    [self.task launch];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

- (void)tearDown {
    [super tearDown];
    [self.task terminate];
    self.task = [[NSTask alloc] init];
    self.task.currentDirectoryPath = [RLMObjectServerTestCase rootRealmCocoaPath];
    self.task.launchPath = @"/bin/sh";
    self.task.arguments = @[@"sync/realm-object-server-1.0.0-beta-15.0/reset-server-realms.command"];
    self.task.standardOutput = [NSPipe pipe];
    [self.task launch];
    [self.task waitUntilExit];
}

- (void)testUsernamePasswordAuthentication {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser authenticateWithCredential:[RLMSyncCredential credentialWithUsername:@"test" password:@"test"]
                                    actions:RLMAuthenticationActionsCreateAccount
                              authServerURL:[NSURL URLWithString:@"http://127.0.0.1:8080"]
                               onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNotNil(user);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
