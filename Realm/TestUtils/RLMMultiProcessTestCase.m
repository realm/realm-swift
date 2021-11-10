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

#import "RLMMultiProcessTestCase.h"
#import "RLMChildProcessEnvironment.h"

#include <mach-o/dyld.h>

@interface RLMMultiProcessTestCase ()
@property (nonatomic) bool isParent;
@property (nonatomic, strong) NSString *testName;

@property (nonatomic, strong) NSString *xctestPath;
@property (nonatomic, strong) NSString *testsPath;
@end

@interface RLMMultiProcessTestCase (Sync)
- (NSString *)appId;
@end

@implementation RLMMultiProcessTestCase
// Override all of the methods for creating a XCTestCase object to capture the current test name
+ (id)testCaseWithInvocation:(NSInvocation *)invocation {
    RLMMultiProcessTestCase *testCase = [super testCaseWithInvocation:invocation];
    testCase.testName = NSStringFromSelector(invocation.selector);
    return testCase;
}

- (id)initWithInvocation:(NSInvocation *)invocation {
    self = [super initWithInvocation:invocation];
    if (self) {
        self.testName = NSStringFromSelector(invocation.selector);
    }
    return self;
}

+ (id)testCaseWithSelector:(SEL)selector {
    RLMMultiProcessTestCase *testCase = [super testCaseWithSelector:selector];
    testCase.testName = NSStringFromSelector(selector);
    return testCase;
}

- (id)initWithSelector:(SEL)selector {
    self = [super initWithSelector:selector];
    if (self) {
        self.testName = NSStringFromSelector(selector);
    }
    return self;
}

- (BOOL)encryptTests {
    return NO;
}

- (void)setUp {
    self.isParent = !getenv("RLMProcessIsChild");
    self.xctestPath = [self locateXCTest];
    self.testsPath = [NSBundle bundleForClass:[self class]].bundlePath;

    if (!self.isParent) {
        // For multi-process tests, the child's concept of a default path needs to match the parent.
        // RLMRealmConfiguration isn't aware of this, but our test's RLMDefaultRealmURL helper does.
        // Use it to reset the default configuration's path so it matches the parent.
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        configuration.fileURL = RLMDefaultRealmURL();
        [RLMRealmConfiguration setDefaultConfiguration:configuration];
    }

    [super setUp];
}

- (void)invokeTest {
    CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
        [super invokeTest];
        CFRunLoopStop(CFRunLoopGetCurrent());
    });
    CFRunLoopRun();
}

- (void)deleteFiles {
    // Only the parent should delete files in setUp/tearDown
    if (self.isParent) {
        [super deleteFiles];
    }
}

+ (void)preintializeSchema {
    // Do nothing so that we can test global schema init in child processes
}

- (NSString *)locateXCTest {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSString *pathString = info.environment[@"PATH"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *directory in [pathString componentsSeparatedByString:@":"]) {
        NSString *candidatePath = [directory stringByAppendingPathComponent:@"xctest"];
        if ([fileManager isExecutableFileAtPath:candidatePath])
            return candidatePath;
    }
    return info.arguments[0];
}

#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
- (NSTask *)childTaskWithEnvironment:(RLMChildProcessEnvironment *)environment {
    NSString *testName = [NSString stringWithFormat:@"%@/%@", self.className, self.testName];
    NSMutableDictionary *env = [NSProcessInfo.processInfo.environment mutableCopy];
    env[@"RLMProcessIsChild"] = @"true";
    env[@"RLMParentProcessBundleID"] = [NSBundle mainBundle].bundleIdentifier;
    [env addEntriesFromDictionary:[environment dictionaryValue]];

    // If we're running with address sanitizer or thread sanitizer we need to
    // explicitly tell dyld to inject the appropriate runtime library into
    // the child process
    for (int  i = 0, count = _dyld_image_count(); i < count; i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (imageName && strstr(imageName, "libclang_rt")) {
            env[@"DYLD_INSERT_LIBRARIES"] = @(imageName);
        }
    }

    // Don't inherit the config file in the subprocess, as multiple XCTest
    // processes talking to a single Xcode instance doesn't work at all
    [env removeObjectForKey:@"XCTestConfigurationFilePath"];
    [env removeObjectForKey:@"XCTestSessionIdentifier"];
    [env removeObjectForKey:@"XPC_SERVICE_NAME"];
    [env removeObjectForKey:@"XCTestBundlePath"];

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = self.xctestPath;
    task.arguments = @[@"-XCTest", testName, self.testsPath];
    task.environment = env;
    task.standardError = nil;
    return task;
}

- (NSTask *)childTaskWithAppIds:(NSArray *)appIds {
    return [self childTaskWithEnvironment:[[RLMChildProcessEnvironment new] initWithAppIds:appIds
                                                                                     email:nil
                                                                                  password:nil
                                                                                 identifer:0]];
}

- (NSTask *)childTask {
    return [self childTaskWithAppIds:@[]];
}

- (NSPipe *)filterPipe {
    NSPipe *pipe = [NSPipe pipe];
    NSMutableData *buffer = [[NSMutableData alloc] init];

    // Filter the output from the child process to reduce xctest noise
    pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *file) {
        [buffer appendData:[file availableData]];
        const char *newline;
        const char *start = buffer.bytes;
        const char *end = start + buffer.length;
        while ((newline = memchr(start, '\n', end - start))) {
            if (newline < start + 17 ||
                (memcmp(start, "Test Suite", 10) && memcmp(start, "Test Case", 9) && memcmp(start, "     Executed 1 test", 17))) {
                fwrite(start, newline - start + 1, 1, stderr);
            }
            start = newline + 1;
        }

        // Remove everything up to the last newline, leaving any data not newline-terminated in the buffer
        [buffer replaceBytesInRange:NSMakeRange(0, start - (char *)buffer.bytes) withBytes:0 length:0];
    };
    return pipe;
}

- (int)runChildAndWaitWithEnvironment:(RLMChildProcessEnvironment *)environment {
    NSTask *task = [self childTaskWithEnvironment:environment];
    task.standardError = self.filterPipe;
    [task launch];
    [task waitUntilExit];
    return task.terminationStatus;
}

- (int)runChildAndWaitWithAppIds:(NSArray *)appIds {
    return [self runChildAndWaitWithEnvironment:[[RLMChildProcessEnvironment new] initWithAppIds:appIds email:nil password:nil identifer:0]];
}

- (int)runChildAndWait {
    NSTask *task = [self childTask];
    task.standardError = self.filterPipe;
    [task launch];
    [task waitUntilExit];
    return task.terminationStatus;
}

#else
- (NSTask *)childTask {
    return nil;
}
- (NSTask *)childTaskWithAppIds:(__unused NSArray *)appIds {
    return nil;
}

- (int)runChildAndWait {
    return 1;
}

- (int)runChildAndWaitWithAppIds:(__unused NSArray *)appIds {
    return 1;
}

- (int)runChildAndWaitWithEnvironment:(RLMChildProcessEnvironment *)environment {
    return 1;
}
#endif
@end
