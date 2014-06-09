Pod::Spec.new do |s|
  s.name                = "Realm"
  s.version             = "0.21.0"
  s.summary             = "Realm is a fantastic object framework for iOS."
  s.description         = <<-DESC
                          Realm is an object framework for iOS. It aims to provide an easier way to handle data in your apps, whether you need in-memory objects, full database persistence, or a simple network cache.
                          Realm’s basic structures look like Objects & Arrays for your language, but provide additional features such as: querying, relationships & graphs, thread safety,easy in/out JSON Mapping & more.
                          A C++ core underneath provides a memory-efficient implementation of these features, with RLMObjects usually consuming less RAM than native Objects. The core also provides an optional persistence layer that can automatically save & retrieve your objects from disk with very high performance.
                          DESC
  s.homepage            = "http://realm.io"
  s.source              = { :http => "http://static.realm.io/downloads/ios/realm-ios-#{s.version}.zip" }
  s.author              = { "Realm" => "help@realm.io" }
  s.platform            = :ios, "7.0"
  s.library             = "stdc++.6"
  s.requires_arc        = true
  s.social_media_url    = 'https://twitter.com/realm'
  s.documentation_url   = "http://realm.io/"
  s.public_header_files = "Realm.framework/Headers/*.h"
  s.vendored_frameworks = "Realm.framework"
  s.license             = {
                            :type => "Copyright",
                            :text => <<-LICENSE
                                        TIGHTDB CONFIDENTIAL
                                        __________________
                        
                                        [2011] - [2014] TightDB Inc
                                        All Rights Reserved.
                        
                                        NOTICE:  All information contained herein is, and remains
                                        the property of TightDB Incorporated and its suppliers,
                                        if any.  The intellectual and technical concepts contained
                                        herein are proprietary to TightDB Incorporated
                                        and its suppliers and may be covered by U.S. and Foreign Patents,
                                        patents in process, and are protected by trade secret or copyright law.
                                        Dissemination of this information or reproduction of this material
                                        is strictly forbidden unless prior written permission is obtained
                                        from TightDB Incorporated.
                                        LICENSE
                          }
end
