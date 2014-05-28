Pod::Spec.new do |s|
  s.name         = "Realm"
  s.version      = "0.20.0"
  s.summary      = "Realm is a fantastic replacement for Core Data & SQLite."
  s.description  = "Realm is a lightweight database that runs inside your mobile apps. It completely replaces SQLite and also provides a high-level, object-oriented interface similar to Core Data, ORMlite, FMDB or MagicalRecord, that is easy to pick up but extremely powerful."
  s.homepage     = "http://realm.io"
  s.source       = { :http => "http://static.realm.io/realm-ios-#{s.version}.zip" }
  s.license      = "Apache 2.0"
  s.author       = "Realm"
  s.platform     = :ios
  s.library      = "stdc++.6"
  s.public_header_files = "Realm.framework/Headers/*.h"
  s.vendored_frameworks = "Realm.framework"
end
