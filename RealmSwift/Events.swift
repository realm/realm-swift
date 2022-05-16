////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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
import Realm.Private
import Foundation
import Combine

/**
 Realm event recording can be used to record all reads and writes performed on
 a Realm and report them to the server. Enable event recording by setting the
 `eventConfiguration` property of the `Realm.Configuration` used to open a
 Realm, and then obtain an `Events` instance with the `events` property on the
 `Realm`.
*/
public struct Events {
    let context: OpaquePointer

    /**
    Begin recording events with the given activity name.

    All queries run and all objects instantiated within an event scope will be
    automatically reported as 'read' events when the scope is ended. All
    objects modified within an event scope will produce 'write' events which
    report the initial state of the object and the new values of all properties
    which changed.
    */
    public func beginScope(activity: String) {
        RLMEventBeginScope(context, activity)
    }

    /**
    End recording the current event scope and report all generated events.

    This function saves the events to disk locally and then
    asynchronously sends them to the server. The optional completion function
    is called when the event data has been successfully persisted, and *not*
    when the actual upload has completed.

    Calls to this function must be paired with calls to `beginScope()` and an
    exception will be thrown if no scope is currently active.
    */
    public func endScope(completion: ((Swift.Error?) -> Void)? = nil) {
        RLMEventEndScope(context, completion)
    }

    /**
    Record a custom event.

    This function saves the event to disk locally and then asynchronously sends
    them to the server. The optional completion function is called when the
    event data has been successfully persisted, and *not* when the actual
    upload has completed.

    This function does not interact with event scopes, and can be called with no active scope.

    - Parameters:
        - activity: The activity name. This is an arbitrary string stored as-in
                    in the `activity` event property.
        - eventType: The type of event. This is an arbitrary string stored
                     as-in in the `eventType` event property.
        - data: The data payload for this event. If supplied, the string stored
                in the `data` event property. Note that while automatically
                generated events all store JSON in this field, custom events
                are not required to do so.
        - completion: An optional completion handler which will be called once
                      the event has either been saved to the event Realm (but
                      not necessarily uploaded to the server) or an error has
                      occurred. A nil error indicates success.
     */
    public func recordEvent(activity: String, eventType: String? = nil, data: String? = nil,
                            completion: ((Swift.Error?) -> Void)? = nil) {
        RLMEventRecordEvent(context, activity, eventType, data, completion)
    }

    /**
    Replace the metadata supplied in the event configuration with new values.

    If called while an event scope is active, the new metadata will not be used
    until the next event scope is begun.

    See ``EventConfiguration.metadata`` for more details on event metdata.
    */
    public func updateMetadata(_ newMetadata: [String: String]) {
        RLMEventUpdateMetadata(context, newMetadata)
    }

    init?(_ realm: Realm) {
        if let context = RLMEventGetContext(realm.rlmRealm) {
            self.context = context
        } else {
            return nil
        }
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, macCatalyst 13.0, macCatalystApplicationExtension 13.0, *)
public extension Events {
    /**
    End recording the current event scope and report all generated events.

    This function saves the events to disk locally and then asynchronously
    sends them to the server. The returned future is fulfilled when the event
    data has been successfully persisted, and *not* when the actual upload has
    completed.

    Calls to this function must be paired with calls to `beginScope()` and an
    exception will be thrown if no scope is currently active.
    */
    @_disfavoredOverload
    func endScope() -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.endScope { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    /**
    Record a custom event.

    This function saves the events to disk locally and then asynchronously
    sends them to the server. The returned future is fulfilled when the event
    data has been successfully persisted, and *not* when the actual upload has
    completed.

    This function does not interact with event scopes, and can be called with no active scope.

    - Parameters:
        - activity: The activity name. This is an arbitrary string stored as-in
                    in the `activity` event property.
        - eventType: The type of event. This is an arbitrary string stored
                     as-in in the `eventType` event property.
        - data: The data payload for this event. If supplied, the string stored
                in the `data` event property. Note that while automatically
                generated events all store JSON in this field, custom events
                are not required to do so.
     */
    @_disfavoredOverload
    func recordEvent(activity: String, eventType: String? = nil, data: String? = nil)
            -> Future<Void, Error> {
        return Future<Void, Error> { promise in
            self.recordEvent(activity: activity, eventType: eventType, data: data) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }
}

extension Realm {
    /// Get the event context for the Realm. Will be `nil` unless an
    /// ``EventConfiguration`` was set while opening the Realm.
    public var events: Events? {
        Events(self)
    }
}

/// Configuration parameters for Realm event recording.
///
/// Enabling Realm event recording is done by setting
/// ``Realm.Configuration.eventConfiguration`` to any non-nil
/// `EventConfiguration`. A default-initialized configuration is valid, but
/// some properties may need to be customized.
///
/// Using Realm event recording requires including the collection `AuditEvent`
/// in your schema defined on the server for the App which you will be writing
/// events to. The schema must contain the following fields:
/// - `_id`: `ObjectId`
/// - `activity`: `String`
/// - `event`: `String?`
/// - `data`: `String?`
/// - `timestamp`: `Date`
/// In addition, there must be a `String?` field for each metadata key used.
@frozen public struct EventConfiguration {
    /// Metadata which is attached to each event generated. Each key in the
    /// metadata dictionary is stored in a column with that name in the event
    /// Realm, and so the schema configured on the server for the AuditEvent
    /// collection must include all metadata fields which will be used. The
    /// metadata fields must be of type `String?` in the server-side schema.
    public var metadata: [String: String]?

    /// The sync user to write event data with. If not supplied, the user from
    /// the Realm being traced will be used. This can be a ``User`` associated
    /// with a different ``App`` from the Realm being traced if desired.
    ///
    /// The user must be associated with a partition-based sync app. If the
    /// traced Realm is using flexible sync, setting this field to a PBS user
    /// is mandatory.
    public var syncUser: User?

    /// A string prepended to the randomly-generated partition values used for
    /// uploading event data to the server. This can be customized to ensure
    /// that you can distinguish event partitions from partitions used by your
    /// application.
    public var partitionPrefix: String = "events"

    /// A logger callback function. This function should be thread-safe as it
    /// may be called from multiple threads simultaneously.
    public typealias LoggerFunction = (SyncLogLevel, String) -> Void
    /// A logger which will be called to report information about the work done
    /// on the background event thread. If `nil`, this is instead reported to
    /// the ``SyncManager``'s logger.
    public var logger: LoggerFunction?

    /// The error handler which will be called if a sync error occurs when
    /// uploading event data. If `nil`, the error will be logged and then
    /// `abort()` will be called. Production usage should always define a
    /// custom error handler unless aborting on error is desired.
    public var errorHandler: ((Swift.Error) -> Void)?

    /// Creates an `EventConfiguration` which enables Realm event recording.
    public init(metadata: [String: String]? = nil, syncUser: User? = nil,
                partitionPrefix: String = "events", logger: LoggerFunction? = nil,
                errorHandler: ((Swift.Error) -> Void)? = nil) {
        self.metadata = metadata
        self.syncUser = syncUser
        self.partitionPrefix = partitionPrefix
        self.logger = logger
        self.errorHandler = errorHandler
    }
}

/// A type which has a custom representation in Realm events.
///
/// By default, objects are serialized to JSON using built-in rules which
/// include every property. If you wish to customize how a class is serialized
/// in events, you can declare it as conforming to this protocol and
/// define `customEventRepresentation()`.
@objc(RLMCustomEventRepresentable)
public protocol CustomEventRepresentable {
    /// Get the custom event serialization for this object.
    ///
    /// This function must return a valid JSON String, as this is included in a
    /// larger JSON document. Implementations of this function should be "pure"
    /// and access no data other than that which is obtainable from the Object
    /// it is called on, and it should not mutate the object which it is called
    /// on. This function is called on a background thread in a somewhat
    /// unusual context, and attempting to access other data is likely to cause
    /// problems.
    @objc func customEventRepresentation() -> String
}
