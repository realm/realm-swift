# coding: utf-8
Pod::Spec.new do |s|
  s.name                    = 'Realm'
  version                   = `sh build.sh get-version`
  s.version                 = version
  s.cocoapods_version       = '>= 1.10'
  s.summary                 = 'Realm is a modern data framework & database for iOS, macOS, tvOS & watchOS.'
  s.description             = <<-DESC
                              The Realm Database, for Objective-C. (If you want to use Realm from Swift, see the “RealmSwift” pod.)

                              Realm is a fast, easy-to-use replacement for Core Data & SQLite. Use it with Atlas Device Sync for realtime, automatic data sync. Works on iOS, macOS, tvOS & watchOS. Learn more and get help at https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/.
                              DESC
  s.homepage                = "https://realm.io"
  s.source                  = { :git => 'https://github.com/realm/realm-swift.git', :tag => "v#{s.version}" }
  s.author                  = { 'Realm' => 'realm-help@mongodb.com' }
  s.library                 = 'c++', 'z', 'compression'
  s.requires_arc            = true
  s.social_media_url        = 'https://twitter.com/realm'
  s.documentation_url       = "https://docs.mongodb.com/realm/sdk/swift"
  s.license                 = { :type => 'Apache 2.0', :file => 'LICENSE' }

  public_header_files       = 'include/Realm.h',

                              # Realm module
                              'include/RLMArray.h',
                              'include/RLMAsymmetricObject.h',
                              'include/RLMAsyncTask.h',
                              'include/RLMCollection.h',
                              'include/RLMConstants.h',
                              'include/RLMDecimal128.h',
                              'include/RLMDictionary.h',
                              'include/RLMEmbeddedObject.h',
                              'include/RLMGeospatial.h',
                              'include/RLMError.h',
                              'include/RLMLogger.h',
                              'include/RLMMigration.h',
                              'include/RLMObject.h',
                              'include/RLMObjectBase.h',
                              'include/RLMObjectId.h',
                              'include/RLMObjectSchema.h',
                              'include/RLMProperty.h',
                              'include/RLMRealm.h',
                              'include/RLMRealmConfiguration.h',
                              'include/RLMResults.h',
                              'include/RLMSchema.h',
                              'include/RLMSectionedResults.h',
                              'include/RLMSet.h',
                              'include/RLMSwiftCollectionBase.h',
                              'include/RLMSwiftValueStorage.h',
                              'include/RLMThreadSafeReference.h',
                              'include/RLMValue.h',

                              # Sync
                              'include/NSError+RLMSync.h',
                              'include/RLMApp.h',
                              'include/RLMAppCredentials.h',
                              'include/RLMBSON.h',
                              'include/RLMInitialSubscriptionsConfiguration.h',
                              'include/RLMNetworkTransport.h',
                              'include/RLMPushClient.h',
                              'include/RLMProviderClient.h',
                              'include/RLMRealm+Sync.h',
                              'include/RLMSyncConfiguration.h',
                              'include/RLMCredentials.h',
                              'include/RLMSyncManager.h',
                              'include/RLMSyncSession.h',
                              'include/RLMUser.h',
                              'include/RLMUserAPIKey.h',
                              'include/RLMAPIKeyAuth.h',
                              'include/RLMEmailPasswordAuth.h',
                              'include/RLMFindOneAndModifyOptions.h',
                              'include/RLMFindOptions.h',
                              'include/RLMMongoClient.h',
                              'include/RLMMongoCollection.h',
                              'include/RLMMongoDatabase.h',
                              'include/RLMUpdateResult.h',
                              'include/RLMSyncSubscription.h',

                              # Realm.Dynamic module
                              'include/RLMRealm_Dynamic.h',
                              'include/RLMObjectBase_Dynamic.h',

                              # Realm.Swift module
                              'include/RLMSwiftObject.h'

                              # Realm.Private module
  private_header_files      = 'include/RLMAccessor.h',
                              'include/RLMApp_Private.h',
                              'include/RLMArray_Private.h',
                              'include/RLMAsyncTask_Private.h',
                              'include/RLMBSON_Private.h',
                              'include/RLMCollection_Private.h',
                              'include/RLMDictionary_Private.h',
                              'include/RLMEvent.h',
                              'include/RLMLogger_Private.h',
                              'include/RLMMongoCollection_Private.h',
                              'include/RLMObjectBase_Private.h',
                              'include/RLMObjectSchema_Private.h',
                              'include/RLMObjectStore.h',
                              'include/RLMObject_Private.h',
                              'include/RLMOptionalBase.h',
                              'include/RLMPropertyBase.h',
                              'include/RLMProperty_Private.h',
                              'include/RLMProviderClient_Private.h',
                              'include/RLMRealmConfiguration_Private.h',
                              'include/RLMRealm_Private.h',
                              'include/RLMResults_Private.h',
                              'include/RLMScheduler.h',
                              'include/RLMSchema_Private.h',
                              'include/RLMSet_Private.h',
                              'include/RLMSwiftProperty.h',
                              'include/RLMSyncConfiguration_Private.h',
                              'include/RLMSyncSubscription_Private.h',
                              'include/RLMUpdateResult_Private.h',
                              'include/RLMUser_Private.h',

  s.ios.frameworks          = 'Security'
  s.ios.weak_framework      = 'UIKit'
  s.tvos.weak_framework     = 'UIKit'
  s.watchos.weak_framework  = 'UIKit'
  s.module_map              = 'Realm/Realm.modulemap'
  s.compiler_flags          = "-DREALM_HAVE_CONFIG -DREALM_COCOA_VERSION='@\"#{s.version}\"' -D__ASSERTMACROS__ -DREALM_ENABLE_SYNC"
  s.prepare_command         = 'sh scripts/setup-cocoapods.sh'
  s.source_files            = private_header_files + ['Realm/*.{m,mm}']
  s.private_header_files    = private_header_files
  s.header_mappings_dir     = 'include'
  s.pod_target_xcconfig     = { 'APPLICATION_EXTENSION_API_ONLY' => 'YES',
                                'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
                                'CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF' => 'NO',
                                'OTHER_CPLUSPLUSFLAGS' => '-isystem "${PODS_ROOT}/Realm/include/core" -fvisibility-inlines-hidden',
                                'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/Realm/include" "${PODS_ROOT}/Realm/include/Realm"',

                                'IPHONEOS_DEPLOYMENT_TARGET_1500' => '12.0',
                                'IPHONEOS_DEPLOYMENT_TARGET_1600' => '12.0',
                                'IPHONEOS_DEPLOYMENT_TARGET_2600' => '12.0',
                                'IPHONEOS_DEPLOYMENT_TARGET' => '$(IPHONEOS_DEPLOYMENT_TARGET_$(XCODE_VERSION_MAJOR))',
                                'MACOSX_DEPLOYMENT_TARGET_1500' => '10.13',
                                'MACOSX_DEPLOYMENT_TARGET_1600' => '10.13',
                                'MACOSX_DEPLOYMENT_TARGET_2600' => '10.13',
                                'MACOSX_DEPLOYMENT_TARGET' => '$(MACOSX_DEPLOYMENT_TARGET_$(XCODE_VERSION_MAJOR))',
                                'WATCHOS_DEPLOYMENT_TARGET_1500' => '4.0',
                                'WATCHOS_DEPLOYMENT_TARGET_1600' => '4.0',
                                'WATCHOS_DEPLOYMENT_TARGET_2600' => '4.0',
                                'WATCHOS_DEPLOYMENT_TARGET' => '$(WATCHOS_DEPLOYMENT_TARGET_$(XCODE_VERSION_MAJOR))',
                                'TVOS_DEPLOYMENT_TARGET_1500' => '12.0',
                                'TVOS_DEPLOYMENT_TARGET_1600' => '12.0',
                                'TVOS_DEPLOYMENT_TARGET_2600' => '12.0',
                                'TVOS_DEPLOYMENT_TARGET' => '$(TVOS_DEPLOYMENT_TARGET_$(XCODE_VERSION_MAJOR))',

                                'OTHER_LDFLAGS' => '"-Wl,-unexported_symbols_list,${PODS_ROOT}/Realm/Configuration/Realm/PrivateSymbols.txt"',
                              }
  s.preserve_paths          = %w(include scripts Configuration/Realm/PrivateSymbols.txt)
  s.resource_bundles        = {'realm_objc_privacy' => ['Realm/PrivacyInfo.xcprivacy']}

  s.ios.deployment_target   = '12.0'
  s.osx.deployment_target   = '10.13'
  s.watchos.deployment_target = '4.0'
  s.tvos.deployment_target = '12.0'

  s.vendored_frameworks  = 'core/realm-monorepo.xcframework'

  s.subspec 'Headers' do |s|
    s.source_files          = public_header_files
    s.public_header_files   = public_header_files
  end
end
