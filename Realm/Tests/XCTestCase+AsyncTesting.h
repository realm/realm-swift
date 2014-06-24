//
//  XCTestCase+AsyncTesting.h
//  AsyncXCTestingKit
//
//  Created by 小野 将司 on 12/03/17.
//  Modified for XCTest by Vincil Bishop
//  Copyright (c) 2012年 AppBankGames Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

typedef NS_ENUM(NSUInteger, XCTAsyncTestCaseStatus) {
    XCTAsyncTestCaseStatusUnknown = 0,
    XCTAsyncTestCaseStatusWaiting,
    XCTAsyncTestCaseStatusSucceeded,
    XCTAsyncTestCaseStatusFailed,
    XCTAsyncTestCaseStatusCancelled,
};

@interface XCTestCase (AsyncTesting)

- (void)XCA_waitForTimeout:(NSTimeInterval)timeout;
- (void)XCA_waitForStatus:(XCTAsyncTestCaseStatus)status timeout:(NSTimeInterval)timeout;
- (void)XCA_waitForStatus:(XCTAsyncTestCaseStatus)expectedStatus timeout:(NSTimeInterval)timeout withBlock:(void(^)(void))block;

- (void)XCA_notify:(XCTAsyncTestCaseStatus)status;
- (void)XCA_notify:(XCTAsyncTestCaseStatus)status withDelay:(NSTimeInterval)delay;

@end

#ifdef XCA_SHORTHAND
@interface XCTestCase (AsyncTestingShortHand)

- (void)waitForTimeout:(NSTimeInterval)timeout;
- (void)waitForStatus:(XCTAsyncTestCaseStatus)status timeout:(NSTimeInterval)timeout;
- (void)waitForStatus:(XCTAsyncTestCaseStatus)expectedStatus timeout:(NSTimeInterval)timeout withBlock:(void(^)(void))block;

- (void)notify:(XCTAsyncTestCaseStatus)status;
- (void)notify:(XCTAsyncTestCaseStatus)status withDelay:(NSTimeInterval)delay;

@end
#endif
