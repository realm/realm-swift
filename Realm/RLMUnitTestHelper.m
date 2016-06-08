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

#import "RLMUnitTestHelper.h"
#import "RLMRealm_Private.h"
#import "RLMRealmConfiguration_Private.h"

@interface RLMUnitTestHelper ()

@property (nonatomic) dispatch_queue_t queue;

@property (nonatomic, readwrite) RLMRealm *onDiskTestRealm;
@property (nonatomic, readwrite) RLMRealm *inMemoryTestRealm;

@end

@implementation RLMUnitTestHelper

- (void)invokeTestWithBlock:(void (^)(void))invokeBlock {
    if (!invokeBlock) {
        NSAssert(NO, @"invokeTestWithBlock: cannot be called with a nil block");
    }
    @autoreleasepool {
        invokeBlock();
    }
    @autoreleasepool {
        if (self.queue) {
            dispatch_sync(self.queue, ^{});
            self.queue = nil;
        }
        [self _cleanup];
    }
}

- (RLMRealm *)onDiskTestRealm {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSURL *url = [manager URLForDirectory:NSCachesDirectory
                                     inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        if (error) {
            @throw [NSException exceptionWithName:@"RLMTestHelperException"
                                           reason:@"Couldn't create on-disk test Realm"
                                         userInfo:@{@"error": error}];
        }
        NSString *thisName = [NSString stringWithFormat:@"RLMUnitTestHelper-%@", [[NSUUID UUID] UUIDString]];
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.fileURL = [url URLByAppendingPathComponent:thisName];

        error = nil;
        _onDiskTestRealm = [RLMRealm realmWithConfiguration:config error:&error];
        if (error) {
            @throw [NSException exceptionWithName:@"RLMTestHelperException"
                                           reason:@"Couldn't create on-disk test Realm"
                                         userInfo:@{@"error": error}];
        }
    });
    return _onDiskTestRealm;
}

- (RLMRealm *)inMemoryTestRealm {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *thisName = [NSString stringWithFormat:@"RLMUnitTestHelper-%@", [[NSUUID UUID] UUIDString]];
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.inMemoryIdentifier = thisName;

        NSError *error = nil;
        _inMemoryTestRealm = [RLMRealm realmWithConfiguration:config error:&error];
        if (error) {
            @throw [NSException exceptionWithName:@"RLMTestHelperException"
                                           reason:@"Couldn't create in-memory test Realm"
                                         userInfo:@{@"error": error}];
        }
    });
    return _inMemoryTestRealm;
}

// MARK: Dispatch

- (void)dispatch:(dispatch_block_t)block {
    if (!self.queue) {
        self.queue = dispatch_queue_create("test background queue", 0);
    }
    dispatch_async(self.queue, ^{
        @autoreleasepool {
            block();
        }
    });
}

- (void)dispatchAndWait:(dispatch_block_t)block {
    [self dispatch:block];
    dispatch_sync(self.queue, ^{});
}


// MARK: Private

- (void)_cleanup {
    [RLMRealm resetRealmState];
    if (_onDiskTestRealm != nil) {
        NSURL *fileURL = _onDiskTestRealm.configuration.fileURL;
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager removeItemAtURL:fileURL error:nil];
        [manager removeItemAtURL:[fileURL URLByAppendingPathExtension:@".lock"] error:nil];
        // TODO: update this if we move the lock file into the .management dir
        [manager removeItemAtURL:[fileURL URLByAppendingPathExtension:@".note"] error:nil];
    }
}

@end
