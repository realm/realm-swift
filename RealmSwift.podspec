Pod::Spec.new do |s|
  # Info
  s.name                      = 'RealmSwift'
  s.version                   = `sh build.sh get-version`
  s.summary                   = 'Realm is a modern data framework & database for iOS, macOS, tvOS & watchOS.'
  s.description               = <<-DESC
                                The Realm Mobile Database, for Swift. (If you want to use Realm from Objective-C, see the “Realm” pod.)

                                The Realm Mobile Database is a fast, easy-to-use replacement for Core Data & SQLite. Use it with the Realm Mobile Platform for realtime, automatic data sync. Works on iOS, macOS, tvOS & watchOS. Learn more and get help at https://realm.io.
                                DESC
  s.homepage                  = 'https://realm.io'
  s.social_media_url          = 'https://twitter.com/realm'
  s.documentation_url         = "https://realm.io/docs/swift/#{s.version}"
  s.source                    = { git: 'https://github.com/realm/realm-cocoa.git', tag: "v#{s.version}", submodules: true }
  s.author                    = { 'Realm' => 'help@realm.io' }
  s.license                   = { type: 'Apache 2.0', file: 'LICENSE' }

  # Platforms
  s.ios.deployment_target     = '8.0'
  s.osx.deployment_target     = '10.9'
  s.tvos.deployment_target    = '9.0'
  s.watchos.deployment_target = '2.0'

  # Compilation
  s.prepare_command           = 'sh build.sh set-swift-version'
  xcconfig                    = { 'SWIFT_WHOLE_MODULE_OPTIMIZATION' => 'YES',
                                  'APPLICATION_EXTENSION_API_ONLY' => 'YES' }
  s.default_subspecs          = 'Sync'

  # Files
  s.preserve_paths            = %w[build.sh]

  s.subspec 'Sync' do |s|
    s.dependency                'Realm', "= #{s.version}"
    s.source_files            = 'RealmSwift/*.swift'
    s.pod_target_xcconfig     = xcconfig.merge({ 'OTHER_SWIFT_FLAGS' => '-DREALM_ENABLE_SYNC' })
  end

  s.subspec 'OSSCore' do |s|
    s.dependency                'Realm/OSSCore', "= #{s.version}"
    s.source_files            = 'RealmSwift/*.swift'
    s.exclude_files           = 'RealmSwift/Sync.swift'
    s.pod_target_xcconfig     = xcconfig
  end
end
