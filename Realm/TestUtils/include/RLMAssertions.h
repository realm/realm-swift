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

#define RLMAssertThrowsWithReason(expression, expected, ...) \
({ \
    NSException *exception = RLMAssertThrows(expression); \
    if (exception) { \
        if ([exception.reason rangeOfString:(expected)].location == NSNotFound) { \
            _XCTRegisterFailure(self, \
                                [_XCTFailureDescription(_XCTAssertion_True, 0, @#expression " (EXPR_STRING) contains " #expected) \
                                 stringByReplacingOccurrencesOfString:@"EXPR_STRING" \
                                                           withString:exception.reason ?: @"<nil>"]); \
        } \
    } \
    exception; \
})

#define RLMAssertThrowsWithCodeMatching(expression, expectedCode, ...) \
({ \
    NSException *exception = RLMAssertThrows(expression, __VA_ARGS__); \
    XCTAssertEqual([exception.userInfo[NSUnderlyingErrorKey] code], expectedCode, __VA_ARGS__); \
})

#define RLMValidateRealmError(macro_error, macro_errnum, macro_description, macro_underlying)            \
({                                                                                                       \
    NSString *macro_dsc = macro_description;                                                             \
    NSString *macro_usl = macro_underlying;                                                              \
    macro_dsc = [macro_dsc lowercaseString];                                                             \
    macro_usl = [macro_usl lowercaseString];                                                             \
    NSError *macro_castErr = (NSError *)macro_error;                                                     \
    XCTAssertNotNil(macro_castErr);                                                                      \
    XCTAssertEqual(macro_castErr.domain, RLMErrorDomain, @"Was expecting the error domain '%@', but got non-interned '%@' instead", RLMErrorDomain, macro_castErr.domain); \
    XCTAssertEqual(macro_castErr.code, macro_errnum);                                                    \
    if (macro_dsc.length) {                                                                              \
        NSString *macro_dscActual = [macro_castErr.userInfo[NSLocalizedDescriptionKey] lowercaseString]; \
        XCTAssertNotNil(macro_dscActual);                                                                \
        XCTAssert([macro_dscActual rangeOfString:macro_dsc].location != NSNotFound, @"Did not find the expected string '%@' in the description string '%@'", macro_dsc, macro_dscActual); \
    }                                                                                                    \
    if (macro_usl.length) {                                                                              \
        NSString *macro_uslActual = [macro_castErr.userInfo[@"Underlying"] lowercaseString];             \
        XCTAssertNotNil(macro_uslActual);                                                                \
        XCTAssert([macro_uslActual rangeOfString:macro_usl].location != NSNotFound, @"Did not find the expected string '%@' in the underlying info string '%@'", macro_usl, macro_uslActual); \
    }                                                                                                    \
})

/// Check that an exception is thrown, and validate additional details about its underlying error.
#define RLMAssertThrowsWithError(macro_expr, macro_except_string, macro_errnum, macro_underlying_string) \
({                                                                                                       \
    NSException *macro_exception = RLMAssertThrowsWithReasonMatching(macro_expr, macro_except_string);   \
    NSError *macro_excErr = (NSError *)(macro_exception.userInfo[NSUnderlyingErrorKey]);                 \
    RLMValidateRealmError(macro_excErr, macro_errnum, nil, macro_underlying_string);                     \
})
