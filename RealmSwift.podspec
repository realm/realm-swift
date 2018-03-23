Pod::Spec.new do |s|
  s.name                      = 'RealmSwift'
  version                     = `sh build.sh get-version`
  s.version                   = version
  s.summary                   = 'Realm is a modern data framework & database for iOS, macOS, tvOS & watchOS.'
  s.description               = <<-DESC
                                The Realm Mobile Database, for Swift. (If you want to use Realm from Objective-C, see the “Realm” pod.)

                                The Realm Mobile Database is a fast, easy-to-use replacement for Core Data & SQLite. Use it with the Realm Mobile Platform for realtime, automatic data sync. Works on iOS, macOS, tvOS & watchOS. Learn more and get help at https://realm.io.
                                DESC
  s.homepage                  = "https://realm.io"
  s.source                    = { :git => 'https://github.com/realm/realm-cocoa.git', :tag => "v#{s.version}", :submodules => true }
  s.author                    = { 'Realm' => 'help@realm.io' }
  s.requires_arc              = true
  s.social_media_url          = 'https://twitter.com/realm'
  has_versioned_docs          = !(version =~ /alpha|beta|rc/)
  s.documentation_url         = "https://realm.io/docs/swift/#{has_versioned_docs ? s.version : 'latest'}"
  s.license                   = { :type => 'Apache 2.0', :file => 'LICENSE' }

  s.dependency 'Realm', "= #{s.version}"
  s.source_files = 'RealmSwift/*.swift'

  s.prepare_command           = 'sh build.sh cocoapods-setup swift'
  s.preserve_paths            = %w(build.sh)

  s.pod_target_xcconfig = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }

  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target    = '9.0'
end
