////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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


import Foundation
import Realm

public protocol _AnyRealmValue { }
extension Int: _AnyRealmValue { }
extension Float: _AnyRealmValue { }
extension String: _AnyRealmValue { }
extension Data: _AnyRealmValue { }
extension Date: _AnyRealmValue { }
extension Object: _AnyRealmValue { }
extension ObjectId: _AnyRealmValue { }
extension Decimal128: _AnyRealmValue { }

public final class AnyRealmValue: RLMValueBase {

    public enum Value {
        case none
        case int(Int)
        case object(Object)

        public var intValue: Int? {
            guard case let .int(i) = self else {
                return nil
            }
            return i
        }

        public func objectValue<T: Object>(_ objectType: T.Type) -> T? {
            guard case let .object(o) = self else {
                return nil
            }
            return o as? T
        }
    }

    public var value: Value {
        set {
            rlmValue = ObjectiveCSupport.convert(value: newValue)
        }
        get {
            ObjectiveCSupport.convert(value: rlmValue)
        }
    }
}

//ObjectiveCSupport+AnyRealmType

public extension ObjectiveCSupport {
    static func convert(value: AnyRealmValue.Value?) -> RLMValue? {
        switch value {
            case let .int(i):
                return i as NSNumber
            case let .object(o):
                return o.unsafeCastToRLMObject()
            default:
                return nil
        }
    }

    static func convert(value: RLMValue?) -> AnyRealmValue.Value {
        guard let value = value else {
            return .none
        }

        switch value.__valueType {
            case RLMPropertyType.int:
            guard let val = value as? NSNumber else {
                return .none
            }
                return .int(val.intValue)
            case RLMPropertyType.object:
                guard let val = value as? RLMObjectBase else {
                    return .none
                }
                return .object(Object.bridging(from: val, with: nil))
        default:
            return .none
        }
    }
}
