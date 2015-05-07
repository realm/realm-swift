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
RLMPrimativeAssertThrows(self, expression,  __VA_ARGS__)

#define RLMPrimativeAssertThrows(self, expression, format...) \
({ \
NSException *__caughtException = nil; \
@try { \
(expression); \
} \
@catch (id exception) { \
__caughtException = exception; \
}\
if (!__caughtException) { \
_XCTRegisterFailure(self, _XCTFailureDescription(_XCTAssertion_Throws, 0, @#expression), format); \
} \
__caughtException; \
})

#define RLMAssertMatches(expression, regex, ...) \
RLMPrimativeAssertMatches(self, expression, regex,  __VA_ARGS__)

#define RLMPrimativeAssertMatches(self, expression, regex, format...) \
({ \
NSString *string = (expression);\
NSRegularExpression *__regex = [NSRegularExpression regularExpressionWithPattern: regex options: 0 error:nil];\
if ([__regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)] == 0) { \
_XCTRegisterFailure(self, [_XCTFailureDescription(_XCTAssertion_True, 0, @#expression @" (EXPR_STRING) matches " @#regex)stringByReplacingOccurrencesOfString:@"EXPR_STRING" withString:string ?: @"<nil>"], format); \
} \
})
