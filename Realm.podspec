Pod::Spec.new do |s|
  # Info
  s.name                 = 'Realm'
  s.version              = `sh build.sh get-version`
  s.summary              = 'Realm is a modern data framework & database for iOS & OS X.'
  s.description          = <<-DESC
                           The Realm database, for Objective-C. (If you want to use Realm from Swift, see the “RealmSwift” pod.)

                           Realm is a mobile database: a replacement for Core Data & SQLite. You can use it on iOS & OS X. Realm is not an ORM on top SQLite: instead it uses its own persistence engine, built for simplicity (& speed). Learn more and get help at https://realm.io
                           DESC
  s.homepage             = 'https://realm.io'
  s.social_media_url     = 'https://twitter.com/realm'
  s.documentation_url    = "https://realm.io/docs/objc/#{s.version}"
  s.source               = { :git => 'https://github.com/realm/realm-cocoa-private.git', :tag => "v#{s.version}", :submodules => true }
  s.author               = { 'Realm' => 'help@realm.io' }
  s.license              = { :type => 'Apache 2.0', :file => 'LICENSE' }

  # Compilation
  s.dependency             'RealmCore', `cat dependencies.list`.match(/^REALM_CORE_VERSION=(.*)$/).captures.first
  s.dependency             'RealmSync', `cat dependencies.list`.match(/^REALM_SYNC_VERSION=(.*)$/).captures.first
  s.libraries            = 'c++'
  s.header_mappings_dir  = 'Realm'
  s.source_files         = 'Realm/*.{h,hpp,m,mm}',
                           'Realm/ObjectStore/src/*.{h,hpp,cpp}',
                           'Realm/ObjectStore/src/impl/*.{h,hpp,cpp}',
                           'Realm/ObjectStore/src/impl/apple/*.{h,hpp,cpp}',
                           'Realm/ObjectStore/src/util/*.{h,hpp,cpp}',
                           'Realm/ObjectStore/src/util/apple/*.{h,hpp,cpp}'
  s.public_header_files  = 'Realm/Realm.h',
                           'Realm/RLMArray.h',
                           'Realm/RLMCollection.h',
                           'Realm/RLMConstants.h',
                           'Realm/RLMListBase.h',
                           'Realm/RLMMigration.h',
                           'Realm/RLMObject.h',
                           'Realm/RLMObjectBase.h',
                           'Realm/RLMObjectSchema.h',
                           'Realm/RLMOptionalBase.h',
                           'Realm/RLMPlatform.h',
                           'Realm/RLMProperty.h',
                           'Realm/RLMRealm.h',
                           'Realm/RLMRealmConfiguration.h',
                           'Realm/RLMResults.h',
                           'Realm/RLMSchema.h',
                           
                           # Dynamic
                           'Realm/*_Dynamic.h',
                           
                           # Sync
                           'Realm/RLMSyncCredential.h',
                           'Realm/RLMRealmConfiguration+Sync.h',
                           'Realm/RLMSyncManager.h',
                           'Realm/RLMSyncSession.h',
                           'Realm/RLMSyncUser.h',
                           'Realm/RLMSyncUtil.h'
  s.private_header_files = 'Realm/{*_Private,RLMAccessor,RLMObjectStore}.h'
  s.exclude_files        = 'Realm/Tests'
  s.module_map           = 'Realm/module.modulemap'
  s.prepare_command      = 'touch Realm/RLMPlatform.h'
  s.compiler_flags       = '-D__ASSERTMACROS__',
                           "-DREALM_COCOA_VERSION='@\"#{s.version}\"'",
                           '-DREALM_ENABLE_ASSERTIONS',
                           '-DREALM_ENABLE_ENCRYPTION'
  s.pod_target_xcconfig  = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES',
                             'CLANG_CXX_LANGUAGE_STANDARD' => 'c++14',
                             'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/RealmCore/src" "${PODS_ROOT}/RealmSync/src" "${PODS_ROOT}/Realm/Realm/ObjectStore/src"' }

  # Platforms
  s.ios.deployment_target     = '7.0'
  s.osx.deployment_target     = '10.9'
  s.tvos.deployment_target    = '9.0'
  s.watchos.deployment_target = '2.0'
end
