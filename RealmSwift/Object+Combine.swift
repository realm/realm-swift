////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Object {
    public func asPublisher() -> AnyPublisher<ObjectChange, Error> {
        let publisher = ObjectChangesPublisher(self)
        return publisher.eraseToAnyPublisher()
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class ObjectChangesSubscription: Subscription {
    var token: NotificationToken?
    var demand: Subscribers.Demand = .unlimited
    
    init<S>(_ object: Object, subscriber: S) where S: Subscriber, Error == S.Failure, ObjectChange == S.Input {
        
        token = object.observe() {
            [weak self] in
            if let s = self, s.demand != .none {
                s.demand = subscriber.receive($0)
            }
        }
    }
    
    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
    }
    
    func cancel() {
        token?.invalidate()
        demand = .none
    }
    
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
struct ObjectChangesPublisher: Publisher {
    
    typealias Output = ObjectChange
    typealias Failure = Error
    
    private let object: Object
    
    public init(_ object: Object) {
        self.object = object
    }
    func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, ObjectChange == S.Input {
        subscriber.receive(subscription: ObjectChangesSubscription(object, subscriber: subscriber))
    }
    
}
