Pod::Spec.new do |s|
  s.name      = 'Realm'
  s.version   = '0.10.0'
  s.license   = {
    :type => 'Closed Beta',
    :text => <<-LICENSE
              Copyright © 2011-2014 TightDB, Inc.

              All rights reserved.

              http://realm.io
    LICENSE
  }
  s.summary   = 'a fantastic replacement for Core Data & SQLite'
  s.homepage  = 'http://realm.io'
  s.author    = { 'Realm' => 'info@realm.io' }
  #s.source    = { :git => "https://github.com/tightdb/tightdb_objc.git", :tag => "v0.10.0" }
  #s.source_files = 'src/realm/objc/*.{h,m}'
  s.source    = { :http => 'http://realm.io/download/realm-ios.zip' }
  s.preserve_paths = 'Realm.framework/*'
  s.source_files = 'Realm.framework/Headers/Realm.h'
  s.frameworks = 'Realm'
  s.xcconfig     = { 'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_ROOT)/Realm"' }
  #s.vendored_frameworks = 'Realm.framework'
  s.platform  = :ios
  s.library   = 'stdc++.6'
  s.requires_arc = true
end
