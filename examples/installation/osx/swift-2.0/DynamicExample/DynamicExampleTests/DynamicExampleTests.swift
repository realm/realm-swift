//
//  DynamicExampleTests.swift
//  DynamicExampleTests
//
//  Created by JP Simard on 6/25/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Cocoa
import XCTest
import DynamicExample
import RealmSwift

class DynamicExampleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        XCTAssertNotNil(MyModel() as AnyObject is Object)
    }
}
