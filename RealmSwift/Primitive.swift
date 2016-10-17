////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Realm

public class RealmInt: Object, ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    
    public dynamic var value: Int = 0
    
    public required init(integerLiteral value: Int) {
        super.init()
        self.value = value
    }
    
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
}

public class RealmDouble: Object, ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    
    public dynamic var value: Double = 0.0
    
    public required init(floatLiteral value: Double) {
        super.init()
        self.value = value
    }
    
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
}

public class RealmString: Object, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    public dynamic var value: String = ""
    
    public required init(stringLiteral value: String) {
        super.init()
        self.value = value
    }
    
    public required init(extendedGraphemeClusterLiteral value: String) {
        super.init()
        self.value = value
    }
    
    public required init(unicodeScalarLiteral value: String) {
        super.init()
        self.value = value
    }
    
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
}
