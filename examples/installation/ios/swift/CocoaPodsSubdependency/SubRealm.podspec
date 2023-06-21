Pod::Spec.new do |s|
  s.name                       = "SubRealm"
  s.version                    = "1.0.0"
  s.summary                    = "Test Realm as a Subdependecy"
  s.description                = <<-DESC
SubRealm contains a cocoapods which uses RealmSwift as a subpendency.
                   DESC
  s.homepage                   = "https://realm.io"
  s.author                     = { 'Realm' => 'realm-help@mongodb.com' }
  s.source                     = { :git => 'https://github.com/realm/realm-swift.git', :tag => "v#{s.version}" }
  s.swift_version              = '5'
  s.ios.deployment_target      = '14.0'
  s.source_files               = "Source/*.{swift}"

  s.dependency  'RealmSwift'
end
