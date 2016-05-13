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

#define RLMAssertThrows(expression, ...) \
    RLMPrimitiveAssertThrows(self, expression,  __VA_ARGS__)

#define RLMPrimitiveAssertThrows(self, expression, format...) \
({ \
    NSException *caughtException = nil; \
    @try { \
        (expression); \
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

#define RLMAssertThrowsWithCodeMatching(expression, expectedCode, ...) \
({ \
    NSException *exception = RLMAssertThrows(expression, __VA_ARGS__); \
    XCTAssertEqual([exception.userInfo[NSUnderlyingErrorKey] code], expectedCode, __VA_ARGS__); \
})

#define RLMValidateRealmError(__error, __errnum, __description, __underlying)                        \
({                                                                                                   \
    NSString *__dsc = __description;                                                                 \
    NSString *__usl = __underlying;                                                                  \
    NSError *__castErr = (NSError *)__error;                                                         \
    XCTAssertNotNil(__castErr);                                                                      \
    XCTAssertEqual(__castErr.domain, RLMErrorDomain);                                                \
    XCTAssertEqual(__castErr.code, __errnum);                                                        \
    if (__dsc.length) {                                                                              \
        NSString *__dscActual = __castErr.userInfo[NSLocalizedDescriptionKey];                       \
        XCTAssertNotNil(__dscActual);                                                                \
        XCTAssert([__dscActual rangeOfString:__dsc].location != NSNotFound);                         \  
    }                                                                                                \
    if (__usl.length) {                                                                              \
        NSString *__uslActual = __castErr.userInfo[@"Underlying"];                                   \
        XCTAssertNotNil(__uslActual);                                                                \
        XCTAssert([__uslActual rangeOfString:__usl].location != NSNotFound);                         \
    }                                                                                                \
})

/// Check that an exception is thrown, and validate additional details about its underlying error.
#define RLMAssertThrowsWithError(__expr, __except_string, __errnum, __underlying_string)               \
({                                                                                                     \
    NSException *__exception = RLMAssertThrowsWithReasonMatching(__expr, __except_string);             \
    NSError *__excErr = (NSError *)(__exception.userInfo[NSUnderlyingErrorKey]);                       \
    RLMValidateRealmError(__excErr, __errnum, nil, __underlying_string);                               \
})
