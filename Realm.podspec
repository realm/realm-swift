Pod::Spec.new do |s|
  s.name                = "Realm"
  s.version             = "0.21.0"
  s.summary             = "Realm is a modern data framework & database for iOS."
  s.description         = <<-DESC
                          Realm is a modern data framework & database for iOS. You can use it purely in memory — or persist to disk with extraordinary performance.
                          
                          Realm’s data structures look like NSObjects and NSArrays, but provide additional features such as: querying, relationships & graphs, thread safety, and more.
                          
                          Realm is not built on SQLite. Instead, a custom C++ core is used to provide memory-efficient access to your data by using Realm objects, which usually consume less RAM than native objects. The core also provides an optional persistence layer that can automatically save and retrieve your objects from disk.

                          Realm offers extraordinary performance compared to SQLite and other persistence solutions. It has been in development since 2011 and powers an app with over 1 million
                          daily active users at a major mobile game company.
                          DESC
  s.homepage            = "http://realm.io"
  s.source              = { :http => "http://static.realm.io/downloads/ios/realm-ios-#{s.version}.zip" }
  s.author              = { "Realm" => "help@realm.io" }
  s.platform            = :ios, "6.0"
  s.library             = "c++"
  s.requires_arc        = true
  s.social_media_url    = "https://twitter.com/realm"
  s.documentation_url   = "http://realm.io/docs/ios/#{s.version}"
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
