import Foundation
import XCTest
@testable import RealmSwift

class BusyTownTests : XCTestCase {
    
    func testFoobar() {
        let expectation = XCTestExpectation(description: "Handle 10 thread hand-offs")
        let busyTown = BusyTown()

        Task {
            while (busyTown.busyCount < 10) {
                try await busyTown.getBusyAsync()
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
}
