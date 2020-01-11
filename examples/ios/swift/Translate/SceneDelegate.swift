import UIKit
import SwiftUI
import RealmSwift
import os

class Translation: Object, Codable {
    private enum CodingKeys: String, CodingKey {
        case originalText, translatedText, to, from
    }

    @objc dynamic var originalText: String
    @objc dynamic var translatedText: String
    @objc dynamic var to: String
    @objc dynamic var from: String

    @objc dynamic var isSaved: Bool = false
}

class UserSettings: Object {
    @objc dynamic var lastLangFrom: String = Locale.current.identifier
    @objc dynamic var lastLangTo: String = "fr"

    let translations: RealmSwift.List<Translation> = RealmSwift.List()
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        let contentView = ContentView()
            .environmentObject(AppEnvironment(app: RealmApp(appId: "translate-utwuv")))

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
