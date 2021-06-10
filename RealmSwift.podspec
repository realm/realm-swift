# coding: utf-8
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
  s.source                    = { :git => 'https://github.com/realm/realm-cocoa.git', :tag => "v#{s.version}" }
  s.author                    = { 'Realm' => 'help@realm.io' }
  s.requires_arc              = true
  s.social_media_url          = 'https://twitter.com/realm'
  s.documentation_url         = "https://realm.io/docs/swift/latest"
  s.license                   = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.ios.deployment_target     = '9.0'
  s.osx.deployment_target     = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target    = '9.0'
  s.preserve_paths            = %w(build.sh)

  s.weak_frameworks = 'SwiftUI'

  s.dependency 'Realm', "= #{s.version}"
  s.source_files = 'RealmSwift/*.swift', 'RealmSwift/Impl/*.swift'
  s.exclude_files = 'RealmSwift/Nonsync.swift'

  s.pod_target_xcconfig = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES' }
end
