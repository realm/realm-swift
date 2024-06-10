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

#import <XCTest/XCTest.h>

#if !TARGET_OS_IOS || __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_14_0
#define RLMConstantInt "NSConstantIntegerNumber"
#define RLMConstantDouble "NSConstantDoubleNumber"
#define RLMConstantFloat "NSConstantFloatNumber"
#define RLMConstantString "__NSCFConstantString"
#else
#define RLMConstantInt "__NSCFNumber"
#define RLMConstantDouble "__NSCFNumber"
#define RLMConstantFloat "__NSCFNumber"
#define RLMConstantString "__NSCFConstantString"
#endif

FOUNDATION_EXTERN
void RLMAssertThrowsWithReasonMatchingSwift(XCTestCase *self,
                                            __attribute__((noescape)) dispatch_block_t block,
                                            NSString *regexString, NSString *message,
                                            NSString *fileName, NSUInteger lineNumber);

FOUNDATION_EXTERN
void RLMAssertThrowsWithName(XCTestCase *self, __attribute__((noescape)) dispatch_block_t block,
                             NSString *name, NSString *message, NSString *fileName,
                             NSUInteger lineNumber);


FOUNDATION_EXTERN
void RLMAssertThrowsWithReasonMatching(XCTestCase *self,
                                       __attribute__((noescape)) dispatch_block_t block,
                                       NSString *regexString, NSString *message,
                                       NSString *fileName, NSUInteger lineNumber);

FOUNDATION_EXTERN
void RLMAssertMatches(XCTestCase *self, __attribute__((noescape)) NSString *(^block)(void),
                      NSString *regexString, NSString *message, NSString *fileName,
                      NSUInteger lineNumber);

FOUNDATION_EXTERN
void RLMAssertThrowsWithReason(XCTestCase *self,
                               __attribute__((noescape)) dispatch_block_t block,
                               NSString *regexString, NSString *message,
                               NSString *fileName, NSUInteger lineNumber);

FOUNDATION_EXTERN
void RLMAssertExceptionReason(XCTestCase *self,
                              NSException *exception, NSString *expected, NSString *expression,
                              NSString *fileName, NSUInteger lineNumber);

FOUNDATION_EXTERN bool RLMHasCachedRealmForPath(NSString *path);

#define RLMAssertThrows(expression, ...) \
    RLMPrimitiveAssertThrows(self, expression,  __VA_ARGS__)

#define RLMPrimitiveAssertThrows(self, expression, format...) \
({ \
    NSException *caughtException = nil; \
    @try { \
        (void)(expression); \
    } \
    @catch (id exception) { \
        caughtException = exception; \
    } \
    if (!caughtException) { \
        _XCTRegisterFailure(self, _XCTFailureDescription(_XCTAssertion_Throws, 0, @#expression), format); \
    } \
    caughtException; \
})

#define RLMAssertMatches(expression, regex, ...) \
    RLMPrimitiveAssertMatches(self, expression, regex,  __VA_ARGS__)

#define RLMPrimitiveAssertMatches(self, expression, regexString, format...) \
({ \
    NSString *string = (expression); \
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:(NSRegularExpressionOptions)0 error:nil]; \
    if ([regex numberOfMatchesInString:string options:(NSMatchingOptions)0 range:NSMakeRange(0, string.length)] == 0) { \
        _XCTRegisterFailure(self, [_XCTFailureDescription(_XCTAssertion_True, 0, @#expression @" (EXPR_STRING) matches " @#regexString) stringByReplacingOccurrencesOfString:@"EXPR_STRING" withString:string ?: @"<nil>"], format); \
    } \
})

#define RLMAssertThrowsWithReasonMatching(expression, regex, ...) \
({ \
    NSException *exception = RLMAssertThrows(expression, __VA_ARGS__); \
    if (exception) { \
        RLMAssertMatches(exception.reason, regex, __VA_ARGS__); \
    } \
    exception; \
})

#define RLMAssertThrowsWithReason(expression, expected) \
({ \
    NSException *exception = RLMAssertThrows(expression); \
    RLMAssertExceptionReason(self, exception, expected, @#expression, @"" __FILE__, __LINE__); \
    exception; \
})

#define RLMAssertThrowsWithCodeMatching(expression, expectedCode, ...) \
({ \
    NSException *exception = RLMAssertThrows(expression, __VA_ARGS__); \
    XCTAssertEqual([(NSError *)exception.userInfo[NSUnderlyingErrorKey] code], expectedCode, __VA_ARGS__); \
})

#define RLMValidateError(error, errDomain, errCode, msg) do {                                           \
    XCTAssertNotNil(error);                                                                             \
    XCTAssertEqual(error.domain, errDomain);                                                            \
    XCTAssertEqual(error.code, errCode);                                                                \
    XCTAssertEqualObjects(error.localizedDescription, msg);                                             \
} while (0)

#define RLMValidateErrorContains(error, errDomain, errCode, msg) do {                                   \
    XCTAssertNotNil(error);                                                                             \
    XCTAssertEqual(error.domain, errDomain);                                                            \
    XCTAssertEqual(error.code, errCode);                                                                \
    XCTAssert([error.localizedDescription containsString:msg],                                          \
              @"'%@' should contain '%@'", error.localizedDescription, msg);                            \
} while (0)

#define RLMValidateRealmError(macroError, errCode, msg, path) do {                                      \
    NSError *error2 = (NSError *)macroError;                                                            \
    RLMValidateError(error2, RLMErrorDomain, errCode, ([NSString stringWithFormat:msg, path]));         \
    XCTAssertEqualObjects(error2.userInfo[NSFilePathErrorKey], path);                                   \
} while (0)

#define RLMValidateRealmErrorContains(macroError, errCode, msg, path) do {                              \
    NSError *error2 = (NSError *)macroError;                                                            \
    RLMValidateErrorContains(error2, RLMErrorDomain, errCode, ([NSString stringWithFormat:msg, path])); \
    XCTAssertEqualObjects(error2.userInfo[NSFilePathErrorKey], path);                                   \
} while (0)

#define RLMAssertRealmException(expr, errCode, msg, path) do {                                          \
    NSException* exception = RLMAssertThrows(expr);                                                     \
    XCTAssertEqual(exception.name, RLMExceptionName);                                                   \
    NSString* reason = [NSString stringWithFormat:msg, path];                                           \
    XCTAssertEqualObjects(exception.reason, reason);                                                    \
    RLMValidateRealmError(exception.userInfo[NSUnderlyingErrorKey], errCode, msg, path);                \
} while (0)

#define RLMAssertRealmExceptionContains(expr, errCode, msg, path) do {                                  \
    NSException* exception = RLMAssertThrows(expr);                                                     \
    XCTAssertEqual(exception.name, RLMExceptionName);                                                   \
    NSString* reason = [NSString stringWithFormat:msg, path];                                           \
    XCTAssert([exception.reason containsString:reason],                                                 \
              @"'%@' should contain '%@'", exception.reason, reason);                                   \
    RLMValidateRealmErrorContains(exception.userInfo[NSUnderlyingErrorKey], errCode, msg, path);        \
} while (0)

// XCTest assertions wrap each assertion in a try/catch to provide nice
// reporting if an assertion unexpectedly throws an exception. This is normally
// quite nice, but becomes a problem with the very large number of assertions
// in the primitive collection test files builds. Replacing these with
// assertions which do not try/catch cuts those files' build times by about
// 75%. The normal XCTest assertions should still be used by default in places
// where it does not cause problems.
#define uncheckedAssertEqual(ex1, ex2) do { \
    __typeof__(ex1) value1 = (ex1); \
    __typeof__(ex2) value2 = (ex2); \
    if (value1 != value2) { \
        NSValue *box1 = [NSValue value:&value1 withObjCType:@encode(__typeof__(ex1))]; \
        NSValue *box2 = [NSValue value:&value2 withObjCType:@encode(__typeof__(ex2))]; \
        _XCTRegisterFailure(nil, _XCTFailureDescription(_XCTAssertion_Equal, 0, @#ex1, @#ex2, _XCTDescriptionForValue(box1), _XCTDescriptionForValue(box2))); \
    } \
} while (0)

#define uncheckedAssertEqualObjects(ex1, ex2) do { \
    id value1 = (ex1); \
    id value2 = (ex2); \
    if (value1 != value2 && ![(id)value1 isEqual:value2]) { \
        _XCTRegisterFailure(nil, _XCTFailureDescription(_XCTAssertion_EqualObjects, 0, @#ex1, @#ex2, value1, value2)); \
    } \
} while (0)

#define uncheckedAssertTrue(ex) uncheckedAssertEqual(ex, true)
#define uncheckedAssertFalse(ex) uncheckedAssertEqual(ex, false)
#define uncheckedAssertNil(ex) uncheckedAssertEqual(ex, nil)
