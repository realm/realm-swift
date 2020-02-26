import Foundation
import RealmSwift
import XCTest

class RealmAppTests: XCTestCase {
    func testApp() throws {
        let app = RealmApp("translate-utwuv")

        let exp = expectation(description: "should login")

        app.logIn(with: SyncCredentials.anonymous(), onCompletion: { user, error in
            if user == nil {
                XCTFail(error?.localizedDescription ?? "unknown failure")
            }
            exp.fulfill()
        })
        wait(for: [exp], timeout: 10)
    }
}
