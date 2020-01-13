import Foundation
import RealmSwift
import XCTest

class RealmAppTests: XCTestCase {
    struct M: Codable {

    }
    func testApp() throws {
        let app = RealmApp(appID: "translate-utwuv")

        let exp = expectation(description: "should login")

        app.auth.logIn(with: SyncCredentials.anonymous(), onCompletion: { user, error in
            if user == nil {
                XCTFail(error?.localizedDescription ?? "unknown failure")
            }
            exp.fulfill()
        })
        wait(for: [exp], timeout: 30)
    }
}
