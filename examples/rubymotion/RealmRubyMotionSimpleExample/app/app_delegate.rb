class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
  	realm = RLMRealm.defaultRealm
    
    realm.beginWriteTransaction
    
    obj = RubyMotionRealmObject.new
    obj.boolCol = true
    obj.intCol = 123
    obj.floatCol = 123.45
    obj.doubleCol = 234.56
    obj.stringCol = "abcd"
    obj.binaryCol = "abcd".dataUsingEncoding(NSUTF8StringEncoding)
    obj.dateCol = NSDate.date
    obj.cBoolCol = true
    obj.longCol = 123456

    # Property types of "id" supports any other type
    obj.mixedCol = true
    obj.mixedCol = 123
    obj.mixedCol = 123.45
    obj.mixedCol = "abcd"
    obj.mixedCol = "abcd".dataUsingEncoding(NSUTF8StringEncoding)
    obj.mixedCol = NSDate.date

    # Object properties are supported
    stringObj = StringObject.new
    stringObj.stringCol = "xyz"
    obj.objectCol = stringObj

    # Array properties are not yet supported in RubyMotion
    # obj.arrayCol.addObject(stringObj)

    realm.addObject(obj)
    
    realm.commitWriteTransaction

    puts RubyMotionRealmObject.allObjects.description
    
    true
  end
end
