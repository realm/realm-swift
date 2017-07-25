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

extension RLMTestCase {
    func assertThrowsWithReasonMatching<T>(_ block: @autoclosure @escaping () -> T, _ regexString: String,
        _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line) {
            RLMAssertThrowsWithReasonMatchingSwift(self, { _ = block() }, regexString, message, fileName, lineNumber)
    }
}

#if !swift(>=3.2)
func XCTAssertEqual<F: FloatingPoint>(_ expression1: F, _ expression2: F, accuracy: F,
                                      _ message: @autoclosure () -> String = "",
                                      file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqualWithAccuracy(expression1, expression2, accuracy: accuracy, message, file: file, line: line)
}
func XCTAssertNotEqual<F: FloatingPoint>(_ expression1: F, _ expression2: F, accuracy: F,
                                         _ message: @autoclosure () -> String = "",
                                         file: StaticString = #file, line: UInt = #line) {
    XCTAssertNotEqualWithAccuracy(expression1, expression2, accuracy, message, file: file, line: line)
}
#endif
