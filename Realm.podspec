Pod::Spec.new do |s|
  s.name                    = 'Realm'
  s.version                 = `sh build.sh get-version`
  s.summary                 = 'Realm is a modern data framework & database for iOS & OS X.'
  s.description             = <<-DESC
                              The Realm database, for Objective-C. (If you want to use Realm from Swift, see the “RealmSwift” pod.)

                              Realm is a mobile database: a replacement for Core Data & SQLite. You can use it on iOS & OS X. Realm is not an ORM on top SQLite: instead it uses its own persistence engine, built for simplicity (& speed). Learn more and get help at https://realm.io
                              DESC
  s.homepage                = "https://realm.io"
  s.source                  = { :git => 'https://github.com/realm/realm-cocoa.git', :tag => "v#{s.version}" }
  s.author                  = { 'Realm' => 'help@realm.io' }
  s.library                 = 'c++'
  s.requires_arc            = true
  s.social_media_url        = 'https://twitter.com/realm'
  s.documentation_url       = "https://realm.io/docs/objc/#{s.version}"
  s.license                 = { :type => 'Apache 2.0', :file => 'LICENSE' }

  public_header_files       = 'include/**/RLMArray.h',
                              'include/**/RLMCollection.h',
                              'include/**/RLMConstants.h',
                              'include/**/RLMDefines.h',
                              'include/**/RLMListBase.h',
                              'include/**/RLMMigration.h',
                              'include/**/RLMObject.h',
                              'include/**/RLMObjectBase.h',
                              'include/**/RLMObjectSchema.h',
                              'include/**/RLMOptionalBase.h',
                              'include/**/RLMPlatform.h',
                              'include/**/RLMProperty.h',
                              'include/**/RLMRealm.h',
                              'include/**/RLMRealmConfiguration.h',
                              'include/**/RLMResults.h',
                              'include/**/RLMSchema.h',
                              'include/**/Realm.h',

                              # Realm.Dynamic module
                              'include/**/RLMRealm_Dynamic.h',
                              'include/**/RLMObjectBase_Dynamic.h'

                              # Realm.Private module
  private_header_files      = 'include/**/*_Private.h',
                              'include/**/RLMAccessor.h',
                              'include/**/RLMListBase.h',
                              'include/**/RLMObjectStore.h',
                              'include/**/RLMOptionalBase.h'

  source_files              = 'Realm/*.{m,mm}',
                              'Realm/ObjectStore/*.cpp',
                              'Realm/ObjectStore/impl/*.cpp',
                              'Realm/ObjectStore/impl/apple/*.cpp'

  s.module_map              = 'Realm/module.modulemap'
  s.compiler_flags          = "-DREALM_HAVE_CONFIG -DREALM_COCOA_VERSION='@\"#{s.version}\"' -D__ASSERTMACROS__"
  s.prepare_command         = 'sh build.sh cocoapods-setup'
  s.source_files            = source_files + private_header_files
  s.private_header_files    = private_header_files
  s.header_mappings_dir     = 'include'
  s.pod_target_xcconfig     = { 'CLANG_CXX_LANGUAGE_STANDARD' => 'compiler-default',
                                'OTHER_CPLUSPLUSFLAGS' => '-std=c++1y $(inherited)',
                                'APPLICATION_EXTENSION_API_ONLY' => 'YES',
                                'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Realm/include/core"',
                                'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Realm/include" "${PODS_ROOT}/Realm/include/Realm"' }
  s.preserve_paths          = %w(build.sh include)

  s.ios.deployment_target   = '7.0'
  s.ios.vendored_library    = 'core/librealm-ios.a'

  s.osx.deployment_target   = '10.9'
  s.osx.vendored_library    = 'core/librealm-macosx.a'

  if s.respond_to?(:watchos)
    s.watchos.deployment_target = '2.0'
    s.watchos.vendored_library  = 'core/librealm-watchos.a'
  end

  if s.respond_to?(:tvos)
    s.tvos.deployment_target = '9.0'
    s.tvos.vendored_library  = 'core/librealm-tvos.a'
  end

  s.subspec 'Headers' do |s|
    s.source_files          = public_header_files
    s.public_header_files   = public_header_files
  end
end
