//
//  AppDelegate.swift
//  CarthageExample
//
//  Created by JP Simard on 6/25/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import UIKit
import RealmSwift

public class MyModel: Object {}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}
