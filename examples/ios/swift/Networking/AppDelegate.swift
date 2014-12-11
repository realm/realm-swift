//
//  AppDelegate.swift
//  SixSquare
//
//  Created by Samuel E. Giddins on 12/9/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import UIKit
import Realm

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let realm: RLMRealm = {
        let fileManager = NSFileManager.defaultManager()
        let writeablePath: String? = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first?.stringByAppendingPathComponent("sixsquare.realm")

        if let path = writeablePath {
            if !fileManager.fileExistsAtPath(path) {
                fileManager.copyItemAtPath(NSBundle.mainBundle().resourcePath!.stringByAppendingPathComponent("sixsquare.realm"), toPath: path, error: nil)
            }
            return RLMRealm(path: path)
        }
        else {
            fatalError("Unable to create realm")
        }
    }()

    func application(application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?)
                     -> Bool {
        // Override point for customization after application launch.
        let viewController = UINavigationController(rootViewController: ViewController(realm: realm))
        window = .Some(UIWindow(frame: UIScreen.mainScreen().bounds))
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}
