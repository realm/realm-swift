Pod::Spec.new do |s|
  s.name     = 'Realm'
  s.version  = '0.10.0'
  s.license      = {
    :type => 'Private Beta',
    :text => <<-LICENSE
              Copyright © 2011-2014 TightDB, Inc.

              All rights reserved.

              http://realm.io
    LICENSE
  }
  s.summary  = 'a fantastic replacement for Core Data & SQLite'
  s.homepage = 'http://realm.io'
  s.author   = { 'Realm' => 'info@realm.io' }
  s.source   = { :http => 'http://realm.io/realm-ios-#{s.version}.zip' }
  s.vendored_frameworks = 'Realm.framework'
  s.library  = 'c++'
  s.platform = :ios
  s.xcconfig  =  {
    'VALID_ARCHS'       => 'arm64 armv7',
    'ONLY_ACTIVE_ARCH'  => 'NO',
    'ARCHS'             => '$(ARCHS_STANDARD_32_BIT)'
  }
end