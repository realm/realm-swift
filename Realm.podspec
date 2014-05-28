Pod::Spec.new do |s|
  s.name         = "Realm"
  s.version      = "0.20.0"
  s.summary      = "Realm is a fantastic object framework for iOS."
  s.description  = <<-DESC
                   Realm is an object framework for iOS. It aims to provide an easier way to handle data in your apps, whether you need in-memory objects, full database persistence, or a simple network cache.
                   Realm’s basic structures look like Objects & Arrays for your language, but provide additional features such as: querying, relationships & graphs, thread safety,easy in/out JSON Mapping & more.
                   A C++ core underneath provides a memory-efficient implementation of these features, with RLMObjects usually consuming less RAM than native Objects. The core also provides an optional persistence layer that can automatically save & retrieve your objects from disk with very high performance.
                   DESC
  s.homepage     = "http://realm.io"
  s.source       = { :http => "http://static.realm.io/downloads/ios/realm-ios-#{s.version}.zip" }
  s.license      = { :type => "Copyright", :file => "LICENSE"}
  s.author       = "Realm"
  s.platform     = :ios, "6.0"
  s.library      = "stdc++.6"
  s.documentation_url = "http://realm.io"
  s.public_header_files = "Realm.framework/Headers/*.h"
  s.vendored_frameworks = "Realm.framework"
  s.requires_arc = true
end
