def self.realm_source_files(include_headers)
  extensions = 'm,mm,cpp'
  extensions += ',h,hpp' if include_headers
  [
    "Realm/*.{#{extensions}}",
    "Realm/ObjectStore/src/*.{#{extensions}}",
    "Realm/ObjectStore/src/impl/*.{#{extensions}}",
    "Realm/ObjectStore/src/impl/apple/*.{#{extensions}}",
    "Realm/ObjectStore/src/util/*.{#{extensions}}",
    "Realm/ObjectStore/src/util/apple/*.{#{extensions}}"
  ]
end

Pod::Spec.new do |s|
  # Info
  s.name              = 'Realm'
  s.version           = `sh build.sh get-version`
  s.summary           = 'Realm is a modern data framework & database for iOS, macOS, tvOS & watchOS.'
  s.description       = <<-DESC
                        The Realm Mobile Database, for Objective-C. (If you want to use Realm from Swift, see the “RealmSwift” pod.)

                        The Realm Mobile Database is a fast, easy-to-use replacement for Core Data & SQLite. Use it with the Realm Mobile Platform for realtime, automatic data sync. Works on iOS, macOS, tvOS & watchOS. Learn more and get help at https://realm.io.
                        DESC
  s.homepage          = 'https://realm.io'
  s.social_media_url  = 'https://twitter.com/realm'
  s.documentation_url = "https://realm.io/docs/objc/#{s.version}"
  s.source            = { :git => 'https://github.com/realm/realm-cocoa.git', :tag => "v#{s.version}", :submodules => true }
  s.author            = { 'Realm' => 'help@realm.io' }
  s.license           = { :type => 'Apache 2.0', :file => 'LICENSE' }

  # Platforms
  s.ios.deployment_target     = '7.0'
  s.osx.deployment_target     = '10.9'
  s.tvos.deployment_target    = '9.0'
  s.watchos.deployment_target = '2.0'

  # Compilation
  s.module_map             = 'Realm/module.modulemap'
  s.prepare_command        = 'sh build.sh cocoapods-setup'
  public_header_files      = 'Realm.h',
                             'RLMArray.h',
                             'RLMCollection.h',
                             'RLMConstants.h',
                             'RLMListBase.h',
                             'RLMMigration.h',
                             'RLMObject.h',
                             'RLMObjectBase.h',
                             'RLMObjectSchema.h',
                             'RLMOptionalBase.h',
                             'RLMPlatform.h',
                             'RLMProperty.h',
                             'RLMRealm.h',
                             'RLMRealmConfiguration.h',
                             'RLMResults.h',
                             'RLMSchema.h',
                             '*_Dynamic.h'
  private_header_files     = '{*_Private,RLMAccessor,RLMObjectStore}.h'
  compiler_flags           = '-D__ASSERTMACROS__',
                             "-DREALM_COCOA_VERSION='@\"#{s.version}\"'",
                             '-DREALM_ENABLE_ASSERTIONS',
                             '-DREALM_ENABLE_ENCRYPTION'
  xcconfig                 = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES',
                               'CLANG_CXX_LANGUAGE_STANDARD' => 'c++14' }
  if ENV['REALM_DISABLE_SYNC']
    s.dependency             'RealmCore'
    s.libraries            = 'c++'
    s.header_mappings_dir  = 'Realm'
    s.public_header_files  = public_header_files.map { |file| "Realm/#{file}" }
    s.private_header_files = "Realm/#{private_header_files}"
    s.source_files         = realm_source_files(true)
    s.exclude_files        = 'Realm/ObjectStore/**/sync*',
                             'Realm/RLMSync*',
                             'Realm/RLMTokenModels.{h,m}',
                             'Realm/RLMRealmConfiguration+Sync.{h,mm}',
                             'Realm/RLMNetworkClient.{h,m}',
                             'Realm/RLMAuthResponseModel.{h,m}'
    s.compiler_flags       = compiler_flags
    s.pod_target_xcconfig  = xcconfig.merge({
                               'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/RealmCore/src" "${PODS_ROOT}/Realm/Realm/ObjectStore/src"'
                             })
  else
    s.libraries            = 'c++', 'z'
    s.header_mappings_dir  = 'include'
    sync_header_files      = 'RLMRealmConfiguration+Sync.h',
                             'RLMSyncConfiguration.h',
                             'RLMSyncCredential.h',
                             'RLMSyncManager.h',
                             'RLMSyncSession.h',
                             'RLMSyncUser.h',
                             'RLMSyncUtil.h'
    public_header_files    = (public_header_files + sync_header_files).map { |file| "include/**/#{file}" }
    private_header_files   = "include/**/#{private_header_files}"
    s.private_header_files = private_header_files
    s.source_files         = realm_source_files(false) + [private_header_files]
    s.compiler_flags       = compiler_flags + ['-DREALM_ENABLE_SYNC', '-DREALM_HAVE_CONFIG']
    s.pod_target_xcconfig  = xcconfig.merge({
                               'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Realm/include/core"',
                               'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Realm/include" "${PODS_ROOT}/Realm/include/Realm"'
                             })
    s.preserve_paths       = %w(include)

    s.ios.vendored_library     = 'core/librealm-ios.a'
    s.osx.vendored_library     = 'core/librealm-macosx.a'
    s.tvos.vendored_library    = 'core/librealm-tvos.a'
    s.watchos.vendored_library = 'core/librealm-watchos.a'

    s.subspec 'Headers' do |s|
      s.source_files        = public_header_files
      s.public_header_files = public_header_files
    end
  end
end
