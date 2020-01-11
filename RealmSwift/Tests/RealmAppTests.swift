import Foundation
import RealmSwift
import XCTest

class RealmAppTests: XCTestCase {
    func testApp() throws {
        let app = RealmApp.app(appId: "translate-utwuv")

        var exp = expectation(description: "should login")
        app.auth.logIn(with: SyncCredentials.anonymous(), onCompletion: { user, error in
            if user == nil {
                XCTFail(error?.localizedDescription ?? "unknown failure")
            }
            exp.fulfill()
        })
        wait(for: [exp], timeout: 30)
    }
}
