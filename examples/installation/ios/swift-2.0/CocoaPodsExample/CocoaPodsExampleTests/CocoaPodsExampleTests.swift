//
//  CocoaPodsExampleTests.swift
//  CocoaPodsExampleTests
//
//  Created by JP Simard on 5/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import UIKit
import XCTest
import CocoaPodsExample
import RealmSwift

class CocoaPodsExampleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        XCTAssertNotNil(MyModel() as AnyObject is Object)
    }
}
