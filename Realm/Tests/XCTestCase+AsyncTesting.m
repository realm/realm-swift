//
//  XCTestCase+AsyncTesting.m
//  AsyncXCTestingKit
//
//  Created by 小野 将司 on 12/03/17.
//  Modified for XCTest by Vincil Bishop
//  Copyright (c) 2012年 AppBankGames Inc. All rights reserved.
//

#import "XCTestCase+AsyncTesting.h"
#import "objc/runtime.h"

static void *kNotified_Key = "kNotified_Key";
static void *kNotifiedStatus_Key = "kNotifiedStatus_Key";
static void *kExpectedStatus_Key = "kExpectedStatus_Key";

static NSString * const kXCTestCaseAsyncTestingCategoryMethodPrefix = @"XCA_";

@implementation XCTestCase (AsyncTesting)

// Big thanks to Saul Mora (https://github.com/casademora)
// for the shorthand implementation of MagicalRecord (https://github.com/magicalpanda/MagicalRecord)
#ifdef XCA_SHORTHAND
+ (void)load {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleNeededMethods];
    });

}
#endif

+ (void)swizzleNeededMethods {

    SEL sourceSelector = @selector(resolveInstanceMethod:);
    SEL targetSelector = @selector(XCA_resolveInstanceMethod:);
    
    Method sourceClassMethod = class_getClassMethod(self, sourceSelector);
    Method targetClassMethod = class_getClassMethod(self, targetSelector);
    
    Class targetMetaClass = objc_getMetaClass([NSStringFromClass(self) cStringUsingEncoding:NSUTF8StringEncoding]);
    
    BOOL methodWasSuccessfullyAdded = class_addMethod(targetMetaClass, sourceSelector,
                                                      method_getImplementation(targetClassMethod),
                                                      method_getTypeEncoding(targetClassMethod));
    
    if (methodWasSuccessfullyAdded) {
        
        class_replaceMethod(targetMetaClass, targetSelector,
                            method_getImplementation(sourceClassMethod),
                            method_getTypeEncoding(sourceClassMethod));
    }
    
}

+ (BOOL)XCA_resolveInstanceMethod:(SEL)originalSelector {
    NSParameterAssert(originalSelector);
    
    BOOL instanceMethodWasResolved = [self XCA_resolveInstanceMethod:originalSelector];
    if (!instanceMethodWasResolved) {
        
        instanceMethodWasResolved = [self addShorthandMethodForNonPrefixedMethod:self selector:originalSelector];
    }
    
    return instanceMethodWasResolved;
}


+ (BOOL)addShorthandMethodForNonPrefixedMethod:(Class)class selector:(SEL)originalSelector {
    NSParameterAssert(class);
    NSParameterAssert(originalSelector);
    
    NSString *originalSelectorString = NSStringFromSelector(originalSelector);
    if ([originalSelectorString hasPrefix:@"_"] || [originalSelectorString hasPrefix:@"init"]) return NO;

    BOOL methodWasSuccessfullyAdded = NO;
    if (![originalSelectorString hasPrefix: kXCTestCaseAsyncTestingCategoryMethodPrefix ]) {
        
        NSString *prefixedSelector = [kXCTestCaseAsyncTestingCategoryMethodPrefix stringByAppendingString:originalSelectorString];
        Method existingMethod = class_getInstanceMethod(class, NSSelectorFromString(prefixedSelector));
        
        if (existingMethod) {
            
            methodWasSuccessfullyAdded = class_addMethod(class,
                                                         originalSelector,
                                                         method_getImplementation(existingMethod),
                                                         method_getTypeEncoding(existingMethod));
            
        }
    }
    return methodWasSuccessfullyAdded;
}


#pragma mark - Public
- (void)XCA_waitForStatus:(XCTAsyncTestCaseStatus)expectedStatus timeout:(NSTimeInterval)timeout withBlock:(void(^)(void))block {
    NSParameterAssert(block);
    NSParameterAssert(timeout > 0);

    self._notified = NO;
    self._expectedStatus = expectedStatus;
    
    block();
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout];
    [self XCA_waitUntilDate:loopUntil];
    
    // Only assert when notified. Do not assert when timed out
    // Fail if not notified
    [self _raiseExceptionIfNeeded];
    
}

- (void)XCA_waitForStatus:(XCTAsyncTestCaseStatus)status timeout:(NSTimeInterval)timeout {
    NSParameterAssert(timeout > 0);
    
    self._notified = NO;
    self._expectedStatus = status;
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout];
    [self XCA_waitUntilDate:loopUntil];
    
    // Only assert when notified. Do not assert when timed out
    // Fail if not notified
    [self _raiseExceptionIfNeeded];
}

- (void)_raiseExceptionIfNeeded {
    
    NSException *exception = nil;
    if (self._notified) {
        
        if (self._notifiedStatus != self._expectedStatus) {
            
            exception = [NSException exceptionWithName:@"ReturnStatusDidNotMatch"
                                                reason:[NSString stringWithFormat:@"Returned status %lu did not match expected status %lu",
                                                        (unsigned long)self._notifiedStatus, (unsigned long)self._expectedStatus]
                                              userInfo:nil];
        }
    } else {
        
        exception = [NSException exceptionWithName:@"TimeOut"
                                            reason:@"Async test timed out."
                                          userInfo:nil];
        
    }
    
    [exception raise];
    
}

- (void)XCA_waitUntilDate:(NSDate *)date {
    NSParameterAssert(date);
    NSParameterAssert([date compare: [NSDate date]] == NSOrderedDescending);
    
    NSDate *dt = [NSDate dateWithTimeIntervalSinceNow:0.1];
    while (!self._notified && [date timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:dt];
        dt = [NSDate dateWithTimeIntervalSinceNow:0.1];
    }
}

- (void)XCA_waitForTimeout:(NSTimeInterval)timeout {
    NSParameterAssert(timeout > 0);
    
    self._notified = NO;
    self._expectedStatus = XCTAsyncTestCaseStatusUnknown;
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:timeout];
    [self XCA_waitUntilDate:loopUntil];
}

- (void)XCA_notify:(XCTAsyncTestCaseStatus)status {
    
    self._notifiedStatus = status;
    // self.notified must be set at the last of this method
    self._notified = YES;
}

- (void)XCA_notify:(XCTAsyncTestCaseStatus)status withDelay:(NSTimeInterval)delay {
    NSParameterAssert(delay > 0);

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf XCA_notify:status];
    });
    
}

#pragma mark - Object Association Helpers -

- (void)_setAssociatedObject:(id)anObject key:(void*)key {
    NSParameterAssert(anObject);
    
    objc_setAssociatedObject(self, key, anObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)_getAssociatedObject:(void*)key {
    
    id anObject = objc_getAssociatedObject(self, key);
    return anObject;
}

#pragma mark - Property Implementations -
- (BOOL)_notified {
    
    NSNumber *valueNumber = [self _getAssociatedObject:kNotified_Key];
    return [valueNumber boolValue];
}

- (void)set_notified:(BOOL)value {
    
    NSNumber *valueNumber = [NSNumber numberWithBool:value];
    [self _setAssociatedObject:valueNumber key:kNotified_Key];
}

- (XCTAsyncTestCaseStatus)_notifiedStatus {
    
    NSNumber *valueNumber = [self _getAssociatedObject:kNotifiedStatus_Key];
    return [valueNumber integerValue];
}

- (void)set_notifiedStatus:(XCTAsyncTestCaseStatus)value {
    
    NSNumber *valueNumber = [NSNumber numberWithUnsignedInteger:value];
    [self _setAssociatedObject:valueNumber key:kNotifiedStatus_Key];
}

- (XCTAsyncTestCaseStatus)_expectedStatus {
    
    NSNumber *valueNumber = [self _getAssociatedObject:kExpectedStatus_Key];
    return [valueNumber integerValue];
}

- (void)set_expectedStatus:(XCTAsyncTestCaseStatus)value {
    
    NSNumber *valueNumber = [NSNumber numberWithUnsignedInteger:value];
    [self _setAssociatedObject:valueNumber key:kExpectedStatus_Key];
}

@end
