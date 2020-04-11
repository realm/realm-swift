////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#if canImport(Combine)
import Combine
import Realm.Private

// MARK: - Protocols

public protocol ObjectKeyIdentifable: Identifiable, Object {
    var id: UInt64 { get }
}

extension ObjectKeyIdentifable {
    public var id: UInt64 {
        RLMObjectBaseGetCombineId(self)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public protocol RealmSubscribable {
    func observe<S>(on queue: DispatchQueue?, _ subscriber: S)
        -> NotificationToken where S: Subscriber, S.Input == Self, S.Failure == Error
    func observe<S>(_ subscriber: S)
        -> NotificationToken where S: Subscriber, S.Input == Void, S.Failure == Never
}

// MARK: - Public API

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension Publisher {
    public func freeze<T>() -> Combine.Publishers.Map<Self, T> where Output: ThreadConfined, T == Output {
        return map { $0.freeze() }
    }

    public func freeze<T: Object>() -> Combine.Publishers.Map<Self, ObjectChange<T>> where Output == ObjectChange<T> {
        return map {
            if case .change(let object, let properties) = $0 {
                return .change(object.freeze(), properties)
            }
            return $0
        }
    }

    public func freeze<T: RealmCollection>()
        -> Combine.Publishers.Map<Self, RealmCollectionChange<T>> where Output == RealmCollectionChange<T> {
            return map {
                switch $0 {
                case .initial(let collection):
                    return .initial(collection.freeze())
                case .update(let collection, deletions: let deletions, insertions: let insertions, modifications: let modifications):
                    return .update(collection.freeze(), deletions: deletions, insertions: insertions, modifications: modifications)
                case .error(let error):
                    return .error(error)
                }
            }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension Publisher where Output: ThreadConfined {
    public func threadSafeReference() -> Publishers.MakeThreadSafe<Self> {
        Publishers.MakeThreadSafe(self)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension Publisher {
    public func threadSafeReference<T: Object>()
        -> Publishers.MakeThreadSafeObjectChangeset<Self, T> where Output == ObjectChange<T> {
            Publishers.MakeThreadSafeObjectChangeset(self)
    }
    public func threadSafeReference<T: RealmCollection>()
        -> Publishers.MakeThreadSafeCollectionChangeset<Self, T> where Output == RealmCollectionChange<T> {
            Publishers.MakeThreadSafeCollectionChangeset(self)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension RealmCollection where Self: RealmSubscribable {
    public var objectWillChange: Publishers.WillChange<Self> {
        Publishers.WillChange(self)
    }
    public var publisher: Publishers.Value<Self> {
        Publishers.Value(self)
    }
    public var changesetPublisher: Publishers.CollectionChangeset<Self> {
        Publishers.CollectionChangeset(self)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public func valuePublisher<T: Object>(_ object: T) -> Publishers.Value<T> {
    Publishers.Value<T>(object)
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public func valuePublisher<T: RealmCollection>(_ collection: T) -> Publishers.Value<T> {
    Publishers.Value<T>(collection)
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public func changesetPublisher<T: Object>(_ object: T) -> Publishers.ObjectChangeset<T> {
    Publishers.ObjectChangeset<T>(object)
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public func changesetPublisher<T: RealmCollection>(_ collection: T) -> Publishers.CollectionChangeset<T> {
    Publishers.CollectionChangeset<T>(collection)
}

// MARK: - Object

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension Object: Combine.ObservableObject {
    public var objectWillChange: Publishers.WillChange<Object> {
        return Publishers.WillChange(self)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension Object: RealmSubscribable {
    public func observe<S: Subscriber>(on queue: DispatchQueue?, _ subscriber: S)
        -> NotificationToken where S.Input: Object, S.Failure == Error {
            return observe(on: queue) { (change: ObjectChange<S.Input>) in
                switch change {
                case .change(let object, _):
                    _ = subscriber.receive(object)
                case .deleted:
                    subscriber.receive(completion: .finished)
                case .error(let error):
                    subscriber.receive(completion: .failure(error))
                }
            }
    }

    public func observe<S: Subscriber>(_ subscriber: S) -> NotificationToken where S.Input == Void, S.Failure == Never {
        return observe { _ in _ = subscriber.receive() }
    }
}

// MARK: - List

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension List: ObservableObject, RealmSubscribable {
    public var objectWillChange: Publishers.WillChange<List> {
        Publishers.WillChange(self)
    }
}

// MARK: - LinkingObjects

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension LinkingObjects: RealmSubscribable {
    public var objectWillChange: Publishers.WillChange<LinkingObjects> {
        Publishers.WillChange(self)
    }
}

// MARK: - Results

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension Results: RealmSubscribable {
    public var objectWillChange: Publishers.WillChange<Results> {
        Publishers.WillChange(self)
    }
}

// MARK: RealmCollection

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension RealmCollection {
    public func observe<S>(on queue: DispatchQueue? = nil, _ subscriber: S)
        -> NotificationToken where S: Subscriber, S.Input == Self, S.Failure == Error {
            // FIXME: we could skip some pointless work in converting the changeset to the Swift type here
            return observe(on: queue) { change in
                switch change {
                case .initial(let collection):
                    _ = subscriber.receive(collection)
                case .update(let collection, deletions: _, insertions: _, modifications: _):
                    _ = subscriber.receive(collection)
                case .error(let error):
                    _ = subscriber.receive(completion: .failure(error))
                }
            }
    }

    public func observe<S: Subscriber>(_ subscriber: S) -> NotificationToken where S.Input == Void, S.Failure == Never {
        return observe(on: nil) { _ in _ = subscriber.receive() }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
extension AnyRealmCollection: RealmSubscribable {
}

// MARK: Subscriptions

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public struct ObservationSubscription: Subscription {
    private var token: NotificationToken

    public var combineIdentifier: CombineIdentifier {
        return CombineIdentifier(token)
    }

    init(token: NotificationToken) {
        self.token = token
    }

    public func request(_ demand: Subscribers.Demand) {
    }

    public func cancel() {
        token.invalidate()
    }
}

// MARK: Publishers

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public enum Publishers {
    static private func realm<S: Scheduler>(_ config: RLMRealmConfiguration, _ scheduler: S) -> Realm? {
        try? Realm(RLMRealm(configuration: config, queue: scheduler as? DispatchQueue))
    }

    public struct WillChange<Collection: RealmSubscribable>: Publisher where Collection: ThreadConfined {
        public typealias Failure = Never
        public typealias Output = Void

        let object: Collection
        public init(_ object: Collection) {
            self.object = object
        }

        public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input {
            subscriber.receive(subscription: ObservationSubscription(token: self.object.observe(subscriber)))
        }
    }

    public struct Value<Collection: RealmSubscribable>: Publisher where Collection: ThreadConfined {
        public typealias Failure = Error
        public typealias Output = Collection

        let object: Collection
        let queue: DispatchQueue?
        public init(_ object: Collection, queue: DispatchQueue? = nil) {
            precondition(object.realm != nil, "Only managed objects can be published")
            self.object = object
            self.queue = queue
        }

        public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input {
            subscriber.receive(subscription: ObservationSubscription(token: self.object.observe(on: queue, subscriber)))
        }

        public func subscribe<S: Scheduler>(on scheduler: S) -> Value<Collection> {
            guard let queue = scheduler as? DispatchQueue else {
                fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
            }
            return Value(object, queue: queue)
        }

        public func receive<S: Scheduler>(on scheduler: S) -> Publishers.Handover<Self, S> {
            return Publishers.Handover(self, scheduler, self.object.realm!)
        }
    }

    public struct Handover<Upstream: Publisher, S: Scheduler>: Publisher where Upstream.Output: ThreadConfined {
        public typealias Failure = Upstream.Failure
        public typealias Output = Upstream.Output

        private let config: RLMRealmConfiguration
        private let upstream: Upstream
        private let scheduler: S

        internal init(_ upstream: Upstream, _ scheduler: S, _ realm: Realm) {
            self.config = realm.rlmRealm.configuration
            self.upstream = upstream
            self.scheduler = scheduler
        }

        public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input {
            let scheduler = self.scheduler
            let config = self.config
            self.upstream
                .map { ThreadSafeReference(to: $0) }
                .receive(on: scheduler)
                .compactMap { realm(config, scheduler)?.resolve($0) }
                .receive(subscriber: subscriber)
        }
    }

    public struct MakeThreadSafe<Upstream: Publisher>: Publisher where Upstream.Output: ThreadConfined {
        public typealias Failure = Upstream.Failure
        public typealias Output = Upstream.Output

        let upstream: Upstream
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }

        public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input {
            self.upstream.receive(subscriber: subscriber)
        }

        public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandover<Upstream, S> {
            DeferredHandover(self.upstream, scheduler)
        }
    }

    public struct DeferredHandover<Upstream: Publisher, S: Scheduler>: Publisher where Upstream.Output: ThreadConfined {
        public typealias Failure = Upstream.Failure
        public typealias Output = Upstream.Output

        private let upstream: Upstream
        private let scheduler: S

        internal init(_ upstream: Upstream, _ scheduler: S) {
            self.upstream = upstream
            self.scheduler = scheduler
        }

        private enum Handover {
            case object(_ object: Output)
            case tsr(_ tsr: ThreadSafeReference<Output>, config: RLMRealmConfiguration)
        }

        public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input {
            let scheduler = self.scheduler
            self.upstream
                .map { (obj: Output) -> Handover in
                    guard let realm = obj.realm, !realm.isFrozen else { return .object(obj) }
                    return .tsr(ThreadSafeReference(to: obj), config: realm.rlmRealm.configuration)
            }
            .receive(on: scheduler)
            .compactMap { (handover: Handover) -> Output? in
                switch handover {
                case .object(let obj):
                    return obj
                case .tsr(let tsr, let config):
                    return realm(config, scheduler)?.resolve(tsr)
                }
            }
            .receive(subscriber: subscriber)
        }
    }

    public struct ObjectChangeset<T: Object>: Publisher {
        public typealias Output = ObjectChange<T>
        public typealias Failure = Never

        let object: T
        let queue: DispatchQueue?
        public init(_ object: T, queue: DispatchQueue? = nil) {
            precondition(object.realm != nil, "Only managed objects can be published")
            self.object = object
            self.queue = queue
        }

        public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input {
            let token = self.object.observe(on: self.queue) { change in
                switch change {
                case .change(let o, let properties):
                    _ = subscriber.receive(.change(o as! T, properties))
                case .error(let error):
                    _ = subscriber.receive(.error(error))
                case .deleted:
                    subscriber.receive(completion: .finished)
                }
            }
            subscriber.receive(subscription: ObservationSubscription(token: token))
        }

        public func subscribe<S: Scheduler>(on scheduler: S) -> ObjectChangeset<T> {
            guard let queue = scheduler as? DispatchQueue else {
                fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
            }
            return ObjectChangeset(object, queue: queue)
        }

        public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverObjectChangeset<Self, T, S> {
            DeferredHandoverObjectChangeset(self, scheduler)
        }
    }

    public struct MakeThreadSafeObjectChangeset<Upstream: Publisher, T: Object>: Publisher where Upstream.Output == ObjectChange<T> {
        public typealias Failure = Upstream.Failure
        public typealias Output = Upstream.Output

        let upstream: Upstream
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }

        public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input {
            self.upstream.receive(subscriber: subscriber)
        }

        public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverObjectChangeset<Upstream, T, S> {
            DeferredHandoverObjectChangeset(self.upstream, scheduler)
        }
    }

    public struct DeferredHandoverObjectChangeset<Upstream: Publisher, T: Object, S: Scheduler>: Publisher where Upstream.Output == ObjectChange<T> {
        public typealias Failure = Upstream.Failure
        public typealias Output = Upstream.Output

        private let upstream: Upstream
        private let scheduler: S

        internal init(_ upstream: Upstream, _ scheduler: S) {
            self.upstream = upstream
            self.scheduler = scheduler
        }

        private enum Handover {
            case passthrough(_ change: ObjectChange<T>)
            case tsr(_ tsr: ThreadSafeReference<T>, _ properties: [PropertyChange], config: RLMRealmConfiguration)
        }

        public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input {
            let scheduler = self.scheduler
            self.upstream
                .map { (change: Output) -> Handover in
                    guard case .change(let obj, let properties) = change else { return .passthrough(change) }
                    guard let realm = obj.realm, !realm.isFrozen else { return .passthrough(change) }
                    return .tsr(ThreadSafeReference(to: obj), properties, config: realm.rlmRealm.configuration)
                }
                .receive(on: scheduler)
                .compactMap { (handover: Handover) -> Output? in
                    switch handover {
                    case .passthrough(let change):
                        return change
                    case .tsr(let tsr, let properties, let config):
                        if let resolved = realm(config, scheduler)?.resolve(tsr) {
                            return .change(resolved, properties)
                        }
                        return nil
                    }
                }
                .receive(subscriber: subscriber)
        }
    }

    public struct CollectionChangeset<Collection: RealmCollection>: Publisher {
        public typealias Output = RealmCollectionChange<Collection>
        public typealias Failure = Never

        let collection: Collection
        let queue: DispatchQueue?
        public init(_ collection: Collection, queue: DispatchQueue? = nil) {
            precondition(collection.realm != nil, "Only managed collections can be published")
            self.collection = collection
            self.queue = queue
        }

        public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Never, Output == S.Input {
            let token = self.collection.observe(on: self.queue) { change in
                _ = subscriber.receive(change)
            }
            subscriber.receive(subscription: ObservationSubscription(token: token))
        }

        public func subscribe<S: Scheduler>(on scheduler: S) -> CollectionChangeset<Collection> {
            guard let queue = scheduler as? DispatchQueue else {
                fatalError("Cannot subscribe on scheduler \(scheduler): only serial dispatch queues are currently implemented.")
            }
            return CollectionChangeset(collection, queue: queue)
        }

        public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverCollectionChangeset<Self, Collection, S> {
            DeferredHandoverCollectionChangeset(self, scheduler)
        }
    }

    public struct MakeThreadSafeCollectionChangeset<Upstream: Publisher, T: RealmCollection>: Publisher where Upstream.Output == RealmCollectionChange<T> {
        public typealias Failure = Upstream.Failure
        public typealias Output = Upstream.Output

        let upstream: Upstream
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }

        public func receive<S>(subscriber: S) where S: Subscriber, S.Failure == Failure, Output == S.Input {
            self.upstream.receive(subscriber: subscriber)
        }

        public func receive<S: Scheduler>(on scheduler: S) -> DeferredHandoverCollectionChangeset<Upstream, T, S> {
            DeferredHandoverCollectionChangeset(self.upstream, scheduler)
        }
    }

    public struct DeferredHandoverCollectionChangeset<Upstream: Publisher, T: RealmCollection, S: Scheduler>: Publisher where Upstream.Output == RealmCollectionChange<T> {
        public typealias Failure = Upstream.Failure
        public typealias Output = Upstream.Output

        private let upstream: Upstream
        private let scheduler: S

        internal init(_ upstream: Upstream, _ scheduler: S) {
            self.upstream = upstream
            self.scheduler = scheduler
        }

        private enum Handover {
            case passthrough(_ change: RealmCollectionChange<T>)
            case initial(_ tsr: ThreadSafeReference<T>, config: RLMRealmConfiguration)
            case update(_ tsr: ThreadSafeReference<T>, deletions: [Int], insertions: [Int], modifications: [Int], config: RLMRealmConfiguration)
        }

        public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Failure, Output == Sub.Input {
            let scheduler = self.scheduler
            self.upstream
                .map { (change: Output) -> Handover in
                    switch change {
                    case .initial(let collection):
                        guard let realm = collection.realm, !realm.isFrozen else { return .passthrough(change) }
                        return .initial(ThreadSafeReference(to: collection), config: realm.rlmRealm.configuration)
                    case .update(let collection, deletions: let deletions, insertions: let insertions, modifications: let modifications):
                        guard let realm = collection.realm, !realm.isFrozen else { return .passthrough(change) }
                        return .update(ThreadSafeReference(to: collection), deletions: deletions, insertions: insertions, modifications: modifications, config: realm.rlmRealm.configuration)
                    case .error:
                        return .passthrough(change)
                    }
                }
                .receive(on: scheduler)
                .compactMap { (handover: Handover) -> Output? in
                    switch handover {
                    case .passthrough(let change):
                        return change
                    case .initial(let tsr, config: let config):
                        if let resolved = realm(config, scheduler)?.resolve(tsr) {
                            return .initial(resolved)
                        }
                        return nil
                    case .update(let tsr, deletions: let deletions, insertions: let insertions, modifications: let modifications, config: let config):
                        if let resolved = realm(config, scheduler)?.resolve(tsr) {
                            return .update(resolved, deletions: deletions, insertions: insertions, modifications: modifications)
                        }
                        return nil
                    }
                }
                .receive(subscriber: subscriber)
        }
    }
}

#endif // canImport(Combine)
