Pod::Spec.new do |s|
  s.name                    = 'RealmSwift'
  s.version                 = `sh build.sh get-version`
  s.summary                 = 'Realm is a modern data framework & database for iOS & OS X.'
  s.description             = <<-DESC
                              The Realm database, for Swift. (If you want to use Realm from Objective-C, see the “Realm” pod.)

                              Realm is a mobile database: a replacement for Core Data & SQLite. You can use it on iOS & OS X. Realm is not an ORM on top SQLite: instead it uses its own persistence engine, built for simplicity (& speed). Learn more and get help at https://realm.io
                              DESC
  s.homepage                = "https://realm.io"
  s.source                  = { :git => 'https://github.com/realm/realm-cocoa.git', :tag => "v#{s.version}" }
  s.author                  = { 'Realm' => 'help@realm.io' }
  s.requires_arc            = true
  s.social_media_url        = 'https://twitter.com/realm'
  s.documentation_url       = "https://realm.io/docs/swift/#{s.version}"
  s.license                 = { :type => 'Apache 2.0', :file => 'LICENSE' }

  s.dependency 'Realm', "= #{s.version}"
  s.source_files = 'RealmSwift/*.swift'

  s.preserve_paths          = %w(build.sh)

  s.ios.deployment_target   = '8.0'
  s.osx.deployment_target   = '10.9'
end
