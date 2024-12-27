Pod::Spec.new do |s|
  s.name                       = "SubRealm"
  s.version                    = "1.0.0"
  s.summary                    = "Test Realm as a transitive dependency"
  s.homepage                   = "https://realm.io"
  s.author                     = { 'Realm' => 'realm-help@mongodb.com' }
  s.license                    = { type: 'Apache 2.0', file: '../../../LICENSE' }
  s.source                     = { git: 'https://github.com/realm/realm-swift.git', tag: "v#{s.version}" }
  s.swift_version              = '5'
  s.ios.deployment_target      = '12.0'
  s.osx.deployment_target      = '10.15'
  s.watchos.deployment_target  = '5.0'
  s.tvos.deployment_target     = '12.0'
  s.visionos.deployment_target = '1.0'
  s.source_files               = "*.swift"
  s.dependency 'RealmSwift'
end
