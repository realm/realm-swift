Pod::Spec.new do |s|
  s.name     = 'realm'
  s.version  = '0.10.0'
  s.license      = {
    :type => 'Closed Beta',
    :text => <<-LICENSE
              Copyright © 2011-2014 TightDB, Inc.

              All rights reserved.

              http://www.realm.io
    LICENSE
  }
  s.summary  = 'a fantastic replacement for Core Data & SQLite'
  s.homepage = 'http://realm.io'
  s.author   = { 'Realm' => 'support@realm.io' }
  s.source   = { :http => 'http://realm.io/download/realm-ios-0.10.0.zip' }
  s.vendored_frameworks = 'Realm.framework'
  s.library  = 'stdc++.6'
  s.public_header_files = "Realm.framework/Headers/*.h"
  s.platform = :ios
end
