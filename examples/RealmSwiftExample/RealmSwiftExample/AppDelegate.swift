//
//  AppDelegate.swift
//  RealmSwiftExample
//
//  Created by JP Simard on 6/10/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import UIKit
import Realm

class SwiftObjCModel: RLMObject {
    @objc var name: NSString?
    @objc var date: NSDate?
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = UIViewController()
        self.window!.makeKeyAndVisible()
        testObjCModel()
        testSwiftObjCModel()
        return true
    }
    
    func testObjCModel() {
        var realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        var obj = ObjCModel()
        obj.name = "test"
        obj.date = NSDate()
        realm.addObject(obj)
        realm.commitWriteTransaction()
        
        var numObjects = realm.allObjects(ObjCModel.className()).count
        println("there are \(numObjects) \(ObjCModel.className()) objects")
    }
    
    func testSwiftObjCModel() {
        var realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        var obj = SwiftObjCModel()
        obj.name = "test"
        obj.date = NSDate()
        realm.addObject(obj)
        realm.commitWriteTransaction()
        
        var numObjects = realm.allObjects(SwiftObjCModel.className()).count
        println("there are \(numObjects) \(SwiftObjCModel.className()) objects")
    }
}
