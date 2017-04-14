def self.realm_source_files(include_headers)
  extensions = 'm,mm,cpp'
  extensions += ',h,hpp' if include_headers
  [
    "Realm/*.{#{extensions}}",
    "Realm/ObjectStore/src/*.{#{extensions}}",
    "Realm/ObjectStore/src/sync/*.{#{extensions}}",
    "Realm/ObjectStore/src/sync/impl/*.{#{extensions}}",
    "Realm/ObjectStore/src/impl/*.{#{extensions}}",
    "Realm/ObjectStore/src/impl/apple/*.{#{extensions}}",
    "Realm/ObjectStore/src/util/*.{#{extensions}}",
    "Realm/ObjectStore/src/util/apple/*.{#{extensions}}"
  ]
end

Pod::Spec.new do |s|
  # Info
  s.name                    = 'Realm'
  s.version                 = `sh build.sh get-version`
  s.summary                 = 'Realm is a modern data framework & database for iOS, macOS, tvOS & watchOS.'
  s.description             = <<-DESC
                              The Realm Mobile Database, for Objective-C. (If you want to use Realm from Swift, see the “RealmSwift” pod.)

                              The Realm Mobile Database is a fast, easy-to-use replacement for Core Data & SQLite. Use it with the Realm Mobile Platform for realtime, automatic data sync. Works on iOS, macOS, tvOS & watchOS. Learn more and get help at https://realm.io.
                              DESC
  s.homepage                = 'https://realm.io'
  s.social_media_url        = 'https://twitter.com/realm'
  s.documentation_url       = "https://realm.io/docs/objc/#{s.version}"
  s.source                  = { git: 'https://github.com/realm/realm-cocoa.git', tag: "v#{s.version}", submodules: true }
  s.author                  = { 'Realm' => 'help@realm.io' }
  s.license                 = { type: 'Apache 2.0', file: 'LICENSE' }

  # Platforms
  s.ios.deployment_target     = '7.0'
  s.osx.deployment_target     = '10.9'
  s.tvos.deployment_target    = '9.0'
  s.watchos.deployment_target = '2.0'

  # Compilation
  s.prepare_command         = 'sh build.sh cocoapods-setup'
  s.module_map              = 'Realm/Realm.modulemap'
  compiler_flags            = '-D__ASSERTMACROS__',
                              "-DREALM_COCOA_VERSION='@\"#{s.version}\"'",
                              '-DREALM_ENABLE_ASSERTIONS',
                              '-DREALM_ENABLE_ENCRYPTION'
  xcconfig                  = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES',
                                'CLANG_CXX_LANGUAGE_STANDARD' => 'c++14' }
  s.default_subspecs        = 'Sync', 'Headers'

  # Files
  public_header_files       = 'Realm.h',
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
                              'RLMThreadSafeReference.h',
                              '*_Dynamic.h'
  private_header_files      = '{*_Private,RLMAccessor,RLMObjectStore}.h'

  s.subspec 'OSSCore' do |s|
    # Compilation
    s.dependency             'RealmCore'
    s.library              = 'c++'
    s.header_mappings_dir  = 'Realm'
    s.compiler_flags       = compiler_flags
    s.pod_target_xcconfig  = xcconfig.merge('HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/RealmCore/src" "${PODS_ROOT}/Realm/Realm/ObjectStore/src"')

    # Files
    s.public_header_files  = public_header_files.map { |file| "Realm/#{file}" }
    s.private_header_files = "Realm/#{private_header_files}"
    s.source_files         = realm_source_files(true)
    s.exclude_files        = 'Realm/ObjectStore/**/sync*',
                             '**/*RLMSync*',
                             'Realm/RLMAuthResponseModel.{h,m}',
                             'Realm/RLMNetworkClient.{h,m}',
                             'Realm/RLMRealmConfiguration+Sync.{h,mm}',
                             'Realm/RLMTokenModels.{h,m}'
  end

  s.subspec 'Sync' do |s|
    # Compilation
    s.libraries            = 'c++', 'z'
    s.header_mappings_dir  = 'include'
    s.compiler_flags       = compiler_flags + ['-DREALM_ENABLE_SYNC', '-DREALM_HAVE_CONFIG']
    s.pod_target_xcconfig  = xcconfig.merge('HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Realm/include/core"',
                                            'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Realm/include" "${PODS_ROOT}/Realm/include/Realm"')

    # Files
    sync_header_files      = 'RLMRealmConfiguration+Sync.h',
                             'RLMSyncConfiguration.h',
                             'RLMSyncCredentials.h',
                             'RLMSyncManager.h',
                             'RLMSyncPermission.h',
                             'RLMSyncPermissionChange.h',
                             'RLMSyncPermissionOffer.h',
                             'RLMSyncPermissionOfferResponse.h',
                             'RLMSyncSession.h',
                             'RLMSyncUser.h',
                             'RLMSyncUtil.h',
                             'NSError+RLMSync.h'
    public_header_files    = (public_header_files + sync_header_files).map { |file| "include/**/#{file}" }
    private_header_files   = "include/**/#{private_header_files}"
    s.private_header_files = private_header_files
    s.source_files         = realm_source_files(false) + [private_header_files]
    s.preserve_paths       = %w[include]

    # Platforms
    s.ios.vendored_library      = 'core/librealmcore-ios.a'
    s.osx.vendored_library      = 'core/librealmcore-macosx.a'
    s.tvos.vendored_library     = 'core/librealmcore-tvos.a'
    s.watchos.vendored_library  = 'core/librealmcore-watchos.a'
  end

  s.subspec 'Headers' do |s|
    s.source_files        = public_header_files
    s.public_header_files = public_header_files
  end
end
