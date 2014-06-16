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
                                        Copyright 2014 Realm Inc.

                                        Licensed under the Apache License, Version 2.0 (the "License");
                                        you may not use this file except in compliance with the License.
                                        You may obtain a copy of the License at

                                        http://www.apache.org/licenses/LICENSE-2.0

                                        Unless required by applicable law or agreed to in writing, software
                                        distributed under the License is distributed on an "AS IS" BASIS,
                                        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                                        See the License for the specific language governing permissions and
                                        limitations under the License.
                          }
end
