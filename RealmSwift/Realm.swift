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

import Realm.Private

/// The Id of the asynchronous transaction.
public typealias AsyncTransactionId = RLMAsyncTransactionId

/**
 A `Realm` instance (also referred to as "a Realm") represents a Realm database.

 Realms can either be stored on disk (see `init(path:)`) or in memory (see `Configuration`).

 `Realm` instances are cached internally, and constructing equivalent `Realm` objects (for example,
 by using the same path or identifier) produces limited overhead.

 If you specifically want to ensure a `Realm` instance is destroyed (for example, if you wish to
 open a Realm, check some property, and then possibly delete the Realm file and re-open it), place
 the code which uses the Realm within an `autoreleasepool {}` and ensure you have no other strong
 references to it.

 - warning: Non-frozen `RLMRealm` instances are thread-confined and cannot be
 shared across threads or dispatch queues. Trying to do so will cause an
 exception to be thrown. You must obtain an instance of `RLMRealm` on each
 thread or queue you want to interact with the Realm on. Realms can be confined
 to a dispatch queue rather than the thread they are opened on by explicitly
 passing in the queue when obtaining the `RLMRealm` instance. If this is not
 done, trying to use the same instance in multiple blocks dispatch to the same
 queue may fail as queues are not always run on the same thread.
 */
@frozen public struct Realm {

    // MARK: Properties

    /// The `Schema` used by the Realm.
    public var schema: Schema { return Schema(rlmRealm.schema) }

    /// The `Configuration` value that was used to create the `Realm` instance.
    public var configuration: Configuration { return Configuration.fromRLMRealmConfiguration(rlmRealm.configuration) }

    /// Indicates if the Realm contains any objects.
    public var isEmpty: Bool { return rlmRealm.isEmpty }

    // MARK: Initializers

    /**
     Obtains an instance of the default Realm.

     The default Realm is persisted as *default.realm* under the *Documents* directory of your Application on iOS, and
     in your application's *Application Support* directory on OS X.

     The default Realm is created using the default `Configuration`, which can be changed by setting the
     `Realm.Configuration.defaultConfiguration` property to a new value.

     - parameter queue: An optional dispatch queue to confine the Realm to. If
                        given, this Realm instance can be used from within
                        blocks dispatched to the given queue rather than on the
                        current thread.
     - throws: An `NSError` if the Realm could not be initialized.
     */
    public init(queue: DispatchQueue? = nil) throws {
        _ = Realm.initMainActor
        let rlmRealm = try RLMRealm(configuration: RLMRealmConfiguration.rawDefault(), queue: queue)
        self.init(rlmRealm)
    }

    /**
     Obtains a `Realm` instance with the given configuration.

     - parameter configuration: A configuration value to use when creating the Realm.
     - parameter queue: An optional dispatch queue to confine the Realm to. If
                        given, this Realm instance can be used from within
                        blocks dispatched to the given queue rather than on the
                        current thread.

     - throws: An `NSError` if the Realm could not be initialized.
     */
    public init(configuration: Configuration, queue: DispatchQueue? = nil) throws {
        _ = Realm.initMainActor
        let rlmRealm = try RLMRealm(configuration: configuration.rlmConfiguration, queue: queue)
        self.init(rlmRealm)
    }

    /**
     Obtains a `Realm` instance persisted at a specified file URL.

     - parameter fileURL: The local URL of the file the Realm should be saved at.

     - throws: An `NSError` if the Realm could not be initialized.
     */
    public init(fileURL: URL) throws {
        _ = Realm.initMainActor
        let configuration = RLMRealmConfiguration.default()
        configuration.fileURL = fileURL
        self.init(try RLMRealm(configuration: configuration))
    }

    private static let initMainActor: Void = {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            RLMSetMainActor(MainActor.shared)
        }
    }()

    // MARK: Async

    /**
     Asynchronously open a Realm and deliver it to a block on the given queue.

     Opening a Realm asynchronously will perform all work needed to get the Realm to
     a usable state (such as running potentially time-consuming migrations) on a
     background thread before dispatching to the given queue. In addition,
     synchronized Realms wait for all remote content available at the time the
     operation began to be downloaded and available locally.

     The Realm passed to the callback function is confined to the callback
     queue as if `Realm(configuration:queue:)` was used.

     - parameter configuration: A configuration object to use when opening the Realm.
     - parameter callbackQueue: The dispatch queue on which the callback should be run.
     - parameter callback:      A callback block. If the Realm was successfully opened, an
                                it will be passed in as an argument.
                                Otherwise, a `Swift.Error` describing what went wrong will be
                                passed to the block instead.
     - returns: A task object which can be used to observe or cancel the async open.
     */
    @discardableResult
    public static func asyncOpen(configuration: Realm.Configuration = .defaultConfiguration,
                                 callbackQueue: DispatchQueue = .main,
                                 callback: @escaping (Result<Realm, Swift.Error>) -> Void) -> AsyncOpenTask {
        return AsyncOpenTask(rlmTask: RLMRealm.asyncOpen(with: configuration.rlmConfiguration, callbackQueue: callbackQueue, callback: { rlmRealm, error in
            if let realm = rlmRealm.flatMap(Realm.init) {
                callback(.success(realm))
            } else {
                callback(.failure(error ?? Realm.Error.callFailed))
            }
        }))
    }

    /**
     Asynchronously open a Realm and deliver it to a block on the given queue.

     Opening a Realm asynchronously will perform all work needed to get the Realm to
     a usable state (such as running potentially time-consuming migrations) on a
     background thread before dispatching to the given queue. In addition,
     synchronized Realms wait for all remote content available at the time the
     operation began to be downloaded and available locally.

     The Realm passed to the publisher is confined to the callback
     queue as if `Realm(configuration:queue:)` was used.

     - parameter configuration: A configuration object to use when opening the Realm.
     - parameter callbackQueue: The dispatch queue on which the AsyncOpenTask should be run.
     - returns: A publisher. If the Realm was successfully opened, it will be received by the subscribers.
                Otherwise, a `Swift.Error` describing what went wrong will be passed upstream instead.
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func asyncOpen(configuration: Realm.Configuration = .defaultConfiguration) -> RealmPublishers.AsyncOpenPublisher {
        return RealmPublishers.AsyncOpenPublisher(configuration: configuration)
    }

    /**
     A task object which can be used to observe or cancel an async open.

     When a synchronized Realm is opened asynchronously, the latest state of the
     Realm is downloaded from the server before the completion callback is
     invoked. This task object can be used to observe the state of the download
     or to cancel it. This should be used instead of trying to observe the
     download via the sync session as the sync session itself is created
     asynchronously, and may not exist yet when Realm.asyncOpen() returns.
     */
    @frozen public struct AsyncOpenTask {
        internal let rlmTask: RLMAsyncOpenTask

        /**
         Cancel the asynchronous open.

         Any download in progress will be cancelled, and the completion block for this
         async open will never be called. If multiple async opens on the same Realm are
         happening concurrently, all other opens will fail with the error "operation cancelled".
         */
        public func cancel() { rlmTask.cancel() }

        /**
         Register a progress notification block.

         Each registered progress notification block is called whenever the sync
         subsystem has new progress data to report until the task is either cancelled
         or the completion callback is called. Progress notifications are delivered on
         the supplied queue.

         - parameter queue: The queue to deliver progress notifications on.
         - parameter block: The block to invoke when notifications are available.
         */
        public func addProgressNotification(queue: DispatchQueue = .main,
                                            block: @escaping (SyncSession.Progress) -> Void) {
            rlmTask.addSyncProgressNotification(on: queue) { progress in
                block(SyncSession.Progress(transferred: progress.transferredBytes, transferrable: progress.transferrableBytes, estimate: progress.progressEstimate))
            }
        }
    }

    // MARK: Transactions

    /**
     Performs actions contained within the given block inside a write transaction.

     If the block throws an error, the transaction will be canceled and any
     changes made before the error will be rolled back.

     Only one write transaction can be open at a time for each Realm file. Write
     transactions cannot be nested, and trying to begin a write transaction on a
     Realm which is already in a write transaction will throw an exception.
     Calls to `write` from `Realm` instances for the same Realm file in other
     threads or other processes will block until the current write transaction
     completes or is cancelled.

     Before beginning the write transaction, `write` updates the `Realm`
     instance to the latest Realm version, as if `refresh()` had been called,
     and generates notifications if applicable. This has no effect if the Realm
     was already up to date.

     You can skip notifiying specific notification blocks about the changes made
     in this write transaction by passing in their associated notification
     tokens. This is primarily useful when the write transaction is saving
     changes already made in the UI and you do not want to have the notification
     block attempt to re-apply the same changes.

     The tokens passed to this function must be for notifications for this Realm
     which were added on the same thread as the write transaction is being
     performed on. Notifications for different threads cannot be skipped using
     this method.

     - parameter tokens: An array of notification tokens which were returned
                         from adding callbacks which you do not want to be
                         notified for the changes made in this write transaction.

     - parameter block: The block containing actions to perform.
     - returns: The value returned from the block, if any.

     - warning: This function is not safe to call from async functions, which
                should use ``asyncWrite`` instead.
     - throws: An `NSError` if the transaction could not be completed successfully.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    @discardableResult
    public func write<Result>(withoutNotifying tokens: [NotificationToken] = [], _ block: (() throws -> Result)) throws -> Result {
        beginWrite()
        let ret: Result
        do {
            ret = try block()
        } catch let error {
            if isInWriteTransaction { cancelWrite() }
            throw error
        }
        if isInWriteTransaction { try commitWrite(withoutNotifying: tokens) }
        return ret
    }

    /**
     Begins a write transaction on the Realm.

     Only one write transaction can be open at a time for each Realm file. Write
     transactions cannot be nested, and trying to begin a write transaction on a
     Realm which is already in a write transaction will throw an exception.
     Calls to `beginWrite` from `Realm` instances for the same Realm file in
     other threads or other processes will block until the current write
     transaction completes or is cancelled.

     Before beginning the write transaction, `beginWrite` updates the `Realm`
     instance to the latest Realm version, as if `refresh()` had been called,
     and generates notifications if applicable. This has no effect if the Realm
     was already up to date.

     It is rarely a good idea to have write transactions span multiple cycles of
     the run loop, but if you do wish to do so you will need to ensure that the
     Realm participating in the write transaction is kept alive until the write
     transaction is committed.

     - warning: This function is not safe to call from async functions, which
                should use ``asyncWrite`` instead.
     */
    public func beginWrite() {
        rlmRealm.beginWriteTransaction()
    }

    /**
     Commits all write operations in the current write transaction, and ends
     the transaction.

     After saving the changes and completing the write transaction, all
     notification blocks registered on this specific `Realm` instance are called
     synchronously. Notification blocks for `Realm` instances on other threads
     and blocks registered for any Realm collection (including those on the
     current thread) are scheduled to be called synchronously.

     You can skip notifiying specific notification blocks about the changes made
     in this write transaction by passing in their associated notification
     tokens. This is primarily useful when the write transaction is saving
     changes already made in the UI and you do not want to have the notification
     block attempt to re-apply the same changes.

     The tokens passed to this function must be for notifications for this Realm
     which were added on the same thread as the write transaction is being
     performed on. Notifications for different threads cannot be skipped using
     this method.

     - warning: This method may only be called during a write transaction.

     - parameter tokens: An array of notification tokens which were returned
                         from adding callbacks which you do not want to be
                         notified for the changes made in this write transaction.

     - throws: An `NSError` if the transaction could not be written due to
               running out of disk space or other i/o errors.
     */
    public func commitWrite(withoutNotifying tokens: [NotificationToken] = []) throws {
        try rlmRealm.commitWriteTransactionWithoutNotifying(tokens)
    }

    /**
     Reverts all writes made in the current write transaction and ends the transaction.

     This rolls back all objects in the Realm to the state they were in at the
     beginning of the write transaction, and then ends the transaction.

     This restores the data for deleted objects, but does not revive invalidated
     object instances. Any `Object`s which were added to the Realm will be
     invalidated rather than becoming unmanaged.

     Given the following code:

     ```swift
     let oldObject = objects(ObjectType).first!
     let newObject = ObjectType()

     realm.beginWrite()
     realm.add(newObject)
     realm.delete(oldObject)
     realm.cancelWrite()
     ```

     Both `oldObject` and `newObject` will return `true` for `isInvalidated`,
     but re-running the query which provided `oldObject` will once again return
     the valid object.

     KVO observers on any objects which were modified during the transaction
     will be notified about the change back to their initial values, but no
     other notifcations are produced by a cancelled write transaction.

     This function is applicable regardless of how a write transaction was
     started. Notably it can be called from inside a block passed to ``write``
     or ``writeAsync``.

     - warning: This method may only be called during a write transaction.
     */
    public func cancelWrite() {
        rlmRealm.cancelWriteTransaction()
    }

    /**
     Indicates whether the Realm is currently in a write transaction.

     - warning:  Do not simply check this property and then start a write transaction whenever an object needs to be
                 created, updated, or removed. Doing so might cause a large number of write transactions to be created,
                 degrading performance. Instead, always prefer performing multiple updates during a single transaction.
     */
    public var isInWriteTransaction: Bool {
        return rlmRealm.inWriteTransaction
    }

    // MARK: Asynchronous Transactions

    /**
     Asynchronously performs actions contained within the given block inside a write transaction.
     The write transaction is begun asynchronously as if calling `beginAsyncWrite`,
     and by default the transaction is committed asynchronously after the block completes.
     You can also explicitly call `commitWrite` or `cancelWrite` from
     within the block to synchronously commit or cancel the write transaction.
     Returning without one of these calls is equivalent to calling `commitWrite`.

     @param block The block containing actions to perform.

     @param completionBlock A block which will be called on the source thread or queue
                        once the commit has either completed or failed with an error.

     @return An id identifying the asynchronous transaction which can be passed to
             `cancelAsyncWrite` prior to the block being called to cancel
             the pending invocation of the block.
    */
    @discardableResult
    public func writeAsync(_ block: @escaping () -> Void, onComplete: ((Swift.Error?) -> Void)? = nil) -> AsyncTransactionId {
        return beginAsyncWrite {
            block()
            commitAsyncWrite(onComplete)
        }
    }

    /**
     Begins an asynchronous write transaction.
     This function asynchronously begins a write transaction on a background
     thread, and then invokes the block on the original thread or queue once the
     transaction has begun. Unlike `beginWrite`, this does not block the
     calling thread if another thread is current inside a write transaction, and
     will always return immediately.
     Multiple calls to this function (or the other functions which perform
     asynchronous write transactions) will queue the blocks to be called in the
     same order as they were queued. This includes calls from inside a write
     transaction block, which unlike with synchronous transactions are allowed.

     @param asyncWriteBlock The block containing actions to perform inside the write transaction.
            `asyncWriteBlock` should end by calling `commitAsyncWrite` or `commitWrite`.
            Returning without one of these calls is equivalent to calling `cancelAsyncWrite`.

     @return An id identifying the asynchronous transaction which can be passed to
             `cancelAsyncWrite` prior to the block being called to cancel
             the pending invocation of the block.
     */
    @discardableResult
    public func beginAsyncWrite(_ asyncWriteBlock: @escaping () -> Void) -> AsyncTransactionId {
        return rlmRealm.beginAsyncWriteTransaction {
            asyncWriteBlock()
        }
    }

    /**
     Asynchronously commits a write transaction.
     The call returns immediately allowing the caller to proceed while the I/O is
     performed on a dedicated background thread. This can be used regardless of if
     the write transaction was begun with `beginWrite` or `beginAsyncWrite`.

     @param onComplete A block which will be called on the source thread or queue once the commit
                     has either completed or failed with an error.

     @param allowGrouping If `true`, multiple sequential calls to `commitAsyncWrite` may be
                          batched together and persisted to stable storage in one group. This
                          improves write performance, particularly when the individual transactions
                          being batched are small. In the event of a crash or power failure,
                          either all of the grouped transactions will be lost or none will, rather
                          than the usual guarantee that data has been persisted as
                          soon as a call to commit has returned.

     @return An id identifying the asynchronous transaction commit can be passed to
             `cancelAsyncWrite` prior to the completion block being called to cancel
             the pending invocation of the block. Note that this does *not* cancel the commit itself.
    */
    @discardableResult
    public func commitAsyncWrite(allowGrouping: Bool = false, _ onComplete: ((Swift.Error?) -> Void)? = nil) -> AsyncTransactionId {
        return rlmRealm.commitAsyncWriteTransaction(onComplete, allowGrouping: allowGrouping)
    }

    /**
     Cancels a queued block for an asynchronous transaction.
     This can cancel a block passed to either an asynchronous begin or an asynchronous commit.
     Canceling a begin cancels that transaction entirely, while canceling a commit merely cancels
     the invocation of the completion callback, and the commit will still happen.
     Transactions can only be canceled before the block is invoked, and calling `cancelAsyncWrite`
     from within the block is a no-op.

     @param AsyncTransactionId A transaction id from either `beginAsyncWrite` or `commitAsyncWrite`.
    */
    public func cancelAsyncWrite(_  asyncTransactionId: AsyncTransactionId) throws {
        rlmRealm.cancelAsyncTransaction(asyncTransactionId)
    }

    /**
     Indicates if the Realm is currently performing async write operations.
     This becomes `true` following a call to `beginAsyncWrite`, `commitAsyncWrite`,
     or `writeAsync`, and remains so until all scheduled async write work has completed.

     - warning: If this is `true`, closing or invalidating the Realm will block until scheduled work has completed.
     */
    public var isPerformingAsynchronousWriteOperations: Bool {
        return rlmRealm.isPerformingAsynchronousWriteOperations
    }

    // MARK: Adding and Creating objects

    /**
     What to do when an object being added to or created in a Realm has a primary key that already exists.
     */
    @frozen public enum UpdatePolicy: Int {
        /**
         Throw an exception. This is the default when no policy is specified for `add()` or `create()`.

         This behavior is the same as passing `update: false` to `add()` or `create()`.
         */
        case error = 1
        /**
         Overwrite only properties in the existing object which are different from the new values. This results
         in change notifications reporting only the properties which changed, and influences the sync merge logic.

         If few or no of the properties are changing this will be faster than .all and reduce how much data has
         to be written to the Realm file. If all of the properties are changing, it may be slower than .all (but
         will never result in *more* data being written).
         */
        case modified = 3
        /**
         Overwrite all properties in the existing object with the new values, even if they have not changed. This
         results in change notifications reporting all properties as changed, and influences the sync merge logic.

         This behavior is the same as passing `update: true` to `add()` or `create()`.
         */
        case all = 2
    }

    /// :nodoc:
    @available(*, unavailable, message: "Pass .error, .modified or .all rather than a boolean. .error is equivalent to false and .all is equivalent to true.")
    public func add(_ object: Object, update: Bool) {
        fatalError()
    }

    /**
     Adds an unmanaged object to this Realm.

     If an object with the same primary key already exists in this Realm, it is updated with the property values from
     this object as specified by the `UpdatePolicy` selected. The update policy must be `.error` for objects with no
     primary key.

     Adding an object to a Realm will also add all child relationships referenced by that object (via `Object` and
     `List<Object>` properties). Those objects must also be valid objects to add to this Realm, and the value of
     the `update:` parameter is propagated to those adds.

     The object to be added must either be an unmanaged object or a valid object which is already managed by this
     Realm. Adding an object already managed by this Realm is a no-op, while adding an object which is managed by
     another Realm or which has been deleted from any Realm (i.e. one where `isInvalidated` is `true`) is an error.

     To copy a managed object from one Realm to another, use `create()` instead.

     - warning: This method may only be called during a write transaction.

     - parameter object: The object to be added to this Realm.
     - parameter update: What to do if an object with the same primary key already exists. Must be `.error` for objects
     without a primary key.
     */
    public func add(_ object: Object, update: UpdatePolicy = .error) {
        if update != .error && object.objectSchema.primaryKeyProperty == nil {
            throwRealmException("'\(object.objectSchema.className)' does not have a primary key and can not be updated")
        }
        RLMAddObjectToRealm(object, rlmRealm, RLMUpdatePolicy(rawValue: UInt(update.rawValue))!)
    }

    /// :nodoc:
    @available(*, unavailable, message: "Pass .error, .modified or .all rather than a boolean. .error is equivalent to false and .all is equivalent to true.")
    public func add<S: Sequence>(_ objects: S, update: Bool) where S.Iterator.Element: Object {
        fatalError()
    }

    /**
     Adds all the objects in a collection into the Realm.

     - see: `add(_:update:)`

     - warning: This method may only be called during a write transaction.

     - parameter objects: A sequence which contains objects to be added to the Realm.
     - parameter update: How to handle
     without a primary key.
     - parameter update: How to handle objects in the collection with a primary key that already exists in this
     Realm. Must be `.error` for object types without a primary key.
     */
    public func add<S: Sequence>(_ objects: S, update: UpdatePolicy = .error) where S.Iterator.Element: Object {
        for obj in objects {
            add(obj, update: update)
        }
    }

    /**
     Creates a Realm object with a given value, adding it to the Realm and returning it.

     The `value` argument can be a Realm object, a key-value coding compliant object, an array
     or dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing
     one element for each managed property. Do not pass in a `LinkingObjects` instance, either
     by itself or as a member of a collection. If the `value` argument is an array, all properties
     must be present, valid and in the same order as the properties defined in the model.

     If the object type does not have a primary key or no object with the specified primary key
     already exists, a new object is created in the Realm. If an object already exists in the Realm
     with the specified primary key and the update policy is `.modified` or `.all`, the existing
     object will be updated and a reference to that object will be returned.

     If the object is being updated, all properties defined in its schema will be set by copying
     from `value` using key-value coding. If the `value` argument does not respond to `value(forKey:)`
     for a given property name (or getter name, if defined), that value will remain untouched.
     Nullable properties on the object can be set to nil by using `NSNull` as the updated value,
     or (if you are passing in an instance of an `Object` subclass) setting the corresponding
     property on `value` to nil.

     - warning: This method may only be called during a write transaction.

     - parameter type:   The type of the object to create.
     - parameter value:  The value used to populate the object.
     - parameter update: What to do if an object with the same primary key already exists. Must be `.error` for object
     types without a primary key.

     - returns: The newly created object.
     */
    @discardableResult
    public func create<T: Object>(_ type: T.Type, value: Any = [String: Any](), update: UpdatePolicy = .error) -> T {
        if update != .error {
            RLMVerifyHasPrimaryKey(type)
        }
        let typeName = (type as Object.Type).className()
        return unsafeDowncast(RLMCreateObjectInRealmWithValue(rlmRealm, typeName, value,
                                                              RLMUpdatePolicy(rawValue: UInt(update.rawValue))!), to: type)
    }

    /**
     This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use the typed method `create(_:value:update:)`.

     Creates or updates an object with the given class name and adds it to the `Realm`, populating
     the object with the given value.

     The `value` argument can be a Realm object, a key-value coding compliant object, an array
     or dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing
     one element for each managed property. Do not pass in a `LinkingObjects` instance, either
     by itself or as a member of a collection. If the `value` argument is an array, all properties
     must be present, valid and in the same order as the properties defined in the model.

     If the object type does not have a primary key or no object with the specified primary key
     already exists, a new object is created in the Realm. If an object already exists in the Realm
     with the specified primary key and the update policy is `.modified` or `.all`, the existing
     object will be updated and a reference to that object will be returned.

     If the object is being updated, all properties defined in its schema will be set by copying
     from `value` using key-value coding. If the `value` argument does not respond to `value(forKey:)`
     for a given property name (or getter name, if defined), that value will remain untouched.
     Nullable properties on the object can be set to nil by using `NSNull` as the updated value,
     or (if you are passing in an instance of an `Object` subclass) setting the corresponding
     property on `value` to nil.


     - warning: This method can only be called during a write transaction.

     - parameter className:  The class name of the object to create.
     - parameter value:      The value used to populate the object.
     - parameter update:     What to do if an object with the same primary key already exists.
     Must be `.error` for object types without a primary key.

     - returns: The created object.

     :nodoc:
     */
    @discardableResult
    public func dynamicCreate(_ typeName: String, value: Any = [String: Any](), update: UpdatePolicy = .error) -> DynamicObject {
        if update != .error && schema[typeName]?.primaryKeyProperty == nil {
            throwRealmException("'\(typeName)' does not have a primary key and can not be updated")
        }
        return noWarnUnsafeBitCast(RLMCreateObjectInRealmWithValue(rlmRealm, typeName, value,
                                                                   RLMUpdatePolicy(rawValue: UInt(update.rawValue))!),
                                   to: DynamicObject.self)
    }

    // MARK: Deleting objects

    /**
     Deletes an object from the Realm. Once the object is deleted it is considered invalidated.

     - warning: This method may only be called during a write transaction.

     - parameter object: The object to be deleted.
     */
    public func delete(_ object: ObjectBase) {
        RLMDeleteObjectFromRealm(object, rlmRealm)
    }

    /**
     Deletes zero or more objects from the Realm.

     Do not pass in a slice to a `Results` or any other auto-updating Realm collection
     type (for example, the type returned by the Swift `suffix(_:)` standard library
     method). Instead, make a copy of the objects to delete using `Array()`, and pass
     that instead. Directly passing in a view into an auto-updating collection may
     result in 'index out of bounds' exceptions being thrown.

     - warning: This method may only be called during a write transaction.

     - parameter objects:   The objects to be deleted. This can be a `List<Object>`,
                            `Results<Object>`, or any other Swift `Sequence` whose
                            elements are `Object`s (subject to the caveats above).
     */
    public func delete<S: Sequence>(_ objects: S) where S.Iterator.Element: ObjectBase {
        for obj in objects {
            delete(obj)
        }
    }

    /**
     Deletes zero or more objects from the Realm.

     - warning: This method may only be called during a write transaction.

     - parameter objects: A list of objects to delete.

     :nodoc:
     */
    public func delete<Element: ObjectBase>(_ objects: List<Element>) {
        rlmRealm.deleteObjects(objects._rlmCollection)
    }

    /**
     Deletes zero or more objects from the Realm.

     - warning: This method may only be called during a write transaction.

     - parameter objects: A map of objects to delete.

     :nodoc:
     */
    public func delete<Key: _MapKey, Value: ObjectBase>(_ map: Map<Key, Value?>) {
        rlmRealm.deleteObjects(map._rlmCollection)
    }

    /**
     Deletes zero or more objects from the Realm.

     - warning: This method may only be called during a write transaction.

     - parameter objects: A `Results` containing the objects to be deleted.

     :nodoc:
     */
    public func delete<Element: ObjectBase>(_ objects: Results<Element>) {
        rlmRealm.deleteObjects(objects.collection)
    }

    /**
     Deletes all objects from the Realm.

     - warning: This method may only be called during a write transaction.
     */
    public func deleteAll() {
        RLMDeleteAllObjectsFromRealm(rlmRealm)
    }

    // MARK: Object Retrieval

    /**
     Returns all objects of the given type stored in the Realm.

     - parameter type: The type of the objects to be returned.

     - returns: A `Results` containing the objects.
     */
    public func objects<Element: RealmFetchable>(_ type: Element.Type) -> Results<Element> {
        return Results(RLMGetObjects(rlmRealm, type.className(), nil))
    }

    /**
     This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use the typed method `objects(type:)`.

     Returns all objects for a given class name in the Realm.

     - parameter typeName: The class name of the objects to be returned.
     - returns: All objects for the given class name as dynamic objects

     :nodoc:
     */
    public func dynamicObjects(_ typeName: String) -> Results<DynamicObject> {
        return Results<DynamicObject>(RLMGetObjects(rlmRealm, typeName, nil))
    }

    /**
     Retrieves the single instance of a given object type with the given primary key from the Realm.

     This method requires that `primaryKey()` be overridden on the given object class.

     - see: `Object.primaryKey()`

     - parameter type: The type of the object to be returned.
     - parameter key:  The primary key of the desired object.

     - returns: An object of type `type`, or `nil` if no instance with the given primary key exists.
     */
    public func object<Element: Object, KeyType>(ofType type: Element.Type, forPrimaryKey key: KeyType) -> Element? {
        return unsafeBitCast(RLMGetObject(rlmRealm, (type as Object.Type).className(),
                                          dynamicBridgeCast(fromSwift: key)) as! RLMObjectBase?,
                             to: Optional<Element>.self)
    }

    /**
     This method is useful only in specialized circumstances, for example, when building
     components that integrate with Realm. If you are simply building an app on Realm, it is
     recommended to use the typed method `objectForPrimaryKey(_:key:)`.

     Get a dynamic object with the given class name and primary key.

     Returns `nil` if no object exists with the given class name and primary key.

     This method requires that `primaryKey()` be overridden on the given subclass.

     - see: Object.primaryKey()

     - warning: This method is useful only in specialized circumstances.

     - parameter className:  The class name of the object to be returned.
     - parameter key:        The primary key of the desired object.

     - returns: An object of type `DynamicObject` or `nil` if an object with the given primary key does not exist.

     :nodoc:
     */
    public func dynamicObject(ofType typeName: String, forPrimaryKey key: Any) -> DynamicObject? {
        return unsafeBitCast(RLMGetObject(rlmRealm, typeName, key) as! RLMObjectBase?, to: Optional<DynamicObject>.self)
    }

    // MARK: Notifications

    /**
     Adds a notification handler for changes made to this Realm, and returns a notification token.

     Notification handlers are called after each write transaction is committed, independent of the thread or process.

     Handler blocks are called on the same thread that they were added on, and may only be added on threads which are
     currently within a run loop. Unless you are specifically creating and running a run loop on a background thread,
     this will normally only be the main thread.

     Notifications can't be delivered as long as the run loop is blocked by other activity. When notifications can't be
     delivered instantly, multiple notifications may be coalesced.

     You must retain the returned token for as long as you want updates to be sent to the block. To stop receiving
     updates, call `invalidate()` on the token.

     - parameter block: A block which is called to process Realm notifications. It receives the following parameters:
                        `notification`: the incoming notification; `realm`: the Realm for which the notification
                        occurred.

     - returns: A token which must be held for as long as you wish to continue receiving change notifications.
     */
    public func observe(_ block: @escaping NotificationBlock) -> NotificationToken {
        return rlmRealm.addNotificationBlock { rlmNotification, _ in
            switch rlmNotification {
            case RLMNotification.DidChange:
                block(.didChange, self)
            case RLMNotification.RefreshRequired:
                block(.refreshRequired, self)
            default:
                fatalError("Unhandled notification type: \(rlmNotification)")
            }
        }
    }

    // MARK: Autorefresh and Refresh

    /**
     Set this property to `true` to automatically update this Realm when changes happen in other threads.

     If set to `true` (the default), changes made on other threads will be reflected in this Realm on the next cycle of
     the run loop after the changes are committed.  If set to `false`, you must manually call `refresh()` on the Realm
     to update it to get the latest data.

     Note that by default, background threads do not have an active run loop and you will need to manually call
     `refresh()` in order to update to the latest version, even if `autorefresh` is set to `true`.

     Even with this property enabled, you can still call `refresh()` at any time to update the Realm before the
     automatic refresh would occur.

     Notifications are sent when a write transaction is committed whether or not automatic refreshing is enabled.

     Disabling `autorefresh` on a `Realm` without any strong references to it will not have any effect, and
     `autorefresh` will revert back to `true` the next time the Realm is created. This is normally irrelevant as it
     means that there is nothing to refresh (as managed `Object`s, `List`s, and `Results` have strong references to the
     `Realm` that manages them), but it means that setting `autorefresh = false` in
     `application(_:didFinishLaunchingWithOptions:)` and only later storing Realm objects will not work.

     Defaults to `true`.
     */
    public var autorefresh: Bool {
        get {
            return rlmRealm.autorefresh
        }
        nonmutating set {
            rlmRealm.autorefresh = newValue
        }
    }

    /**
     Updates the Realm and outstanding objects managed by the Realm to point to
     the most recent data and deliver any applicable notifications.

     By default Realms will automatically refresh in a more efficient way than
     is possible with this function. This function should be avoided when
     possible.

     - warning: This function is not safe to call from async functions, which
                should use ``asyncRefresh`` instead.
     - returns: Whether there were any updates for the Realm. Note that `true`
                may be returned even if no data actually changed.
     */
    @discardableResult
    public func refresh() -> Bool {
        return rlmRealm.refresh()
    }

    // MARK: Frozen Realms

    /// Returns if this Realm is frozen.
    public var isFrozen: Bool {
        return rlmRealm.isFrozen
    }

    /**
     Returns a frozen (immutable) snapshot of this Realm.

     A frozen Realm is an immutable snapshot view of a particular version of a Realm's data. Unlike
     normal Realm instances, it does not live-update to reflect writes made to the Realm, and can be
     accessed from any thread. Writing to a frozen Realm is not allowed, and attempting to begin a
     write transaction will throw an exception.

     All objects and collections read from a frozen Realm will also be frozen.

     - warning: Holding onto a frozen Realm for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
     */
    public func freeze() -> Realm {
        return isFrozen ? self : Realm(rlmRealm.freeze())
    }

    /**
     Returns a live (mutable) reference of this Realm.

     All objects and collections read from the returned Realm reference will no longer be frozen.
     Will return self if called on a Realm that is not already frozen.
     */
    public func thaw() -> Realm {
        return isFrozen ? Realm(rlmRealm.thaw()) : self
    }

    /**
     Returns a frozen (immutable) snapshot of the given object.

     The frozen copy is an immutable object which contains the same data as the given object
     currently contains, but will not update when writes are made to the containing Realm. Unlike
     live objects, frozen objects can be accessed from any thread.

     - warning: Holding onto a frozen object for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
     */
    public func freeze<T: ObjectBase>(_ obj: T) -> T {
        return RLMObjectFreeze(obj) as! T
    }

    /**
     Returns a live (mutable) reference of this object.

     This method creates a managed accessor to a live copy of the same frozen object.
     Will return self if called on an already live object.
     */
    public func thaw<T: ObjectBase>(_ obj: T) -> T? {
        return RLMObjectThaw(obj) as? T
    }

    /**
     Returns a frozen (immutable) snapshot of the given collection.

     The frozen copy is an immutable collection which contains the same data as the given
     collection currently contains, but will not update when writes are made to the containing
     Realm. Unlike live collections, frozen collections can be accessed from any thread.

     - warning: This method cannot be called during a write transaction, or when the Realm is read-only.
     - warning: Holding onto a frozen collection for an extended period while performing write
     transaction on the Realm may result in the Realm file growing to large sizes. See
     `Realm.Configuration.maximumNumberOfActiveVersions` for more information.
    */
    public func freeze<Collection: RealmCollection>(_ collection: Collection) -> Collection {
        return collection.freeze()
    }

    // MARK: Invalidation

    /**
     Invalidates all `Object`s, `Results`, `LinkingObjects`, and `List`s managed by the Realm.

     A Realm holds a read lock on the version of the data accessed by it, so
     that changes made to the Realm on different threads do not modify or delete the
     data seen by this Realm. Calling this method releases the read lock,
     allowing the space used on disk to be reused by later write transactions rather
     than growing the file. This method should be called before performing long
     blocking operations on a background thread on which you previously read data
     from the Realm which you no longer need.

     All `Object`, `Results` and `List` instances obtained from this `Realm` instance on the current thread are
     invalidated. `Object`s and `Array`s cannot be used. `Results` will become empty. The Realm itself remains valid,
     and a new read transaction is implicitly begun the next time data is read from the Realm.

     Calling this method multiple times in a row without reading any data from the
     Realm, or before ever reading any data from the Realm, is a no-op.
     */
    public func invalidate() {
        rlmRealm.invalidate()
    }

    // MARK: File Management

    /**
     Writes a compacted and optionally encrypted copy of the Realm to the given local URL.

     The destination file cannot already exist.

     Note that if this method is called from within a write transaction, the *current* data is written, not the data
     from the point when the previous write transaction was committed.

     - parameter fileURL:       Local URL to save the Realm to.
     - parameter encryptionKey: Optional 64-byte encryption key to encrypt the new file with.

     - throws: An `NSError` if the copy could not be written.
     */
    public func writeCopy(toFile fileURL: URL, encryptionKey: Data? = nil) throws {
        try rlmRealm.writeCopy(to: fileURL, encryptionKey: encryptionKey)
    }

    /**
     Writes a copy of the Realm to a given location specified by a given configuration.

     If the configuration supplied is derived from a `User` then this Realm will be copied with
     sync functionality enabled.

     The destination file cannot already exist.

     - parameter configuration: A Realm Configuration.

     - throws: An `NSError` if the copy could not be written.
     */
    public func writeCopy(configuration: Realm.Configuration) throws {
        try rlmRealm.writeCopy(for: configuration.rlmConfiguration)
    }

    /**
     Checks if the Realm file for the given configuration exists locally on disk.

     For non-synchronized, non-in-memory Realms, this is equivalent to
     `FileManager.default.fileExists(atPath:)`. For synchronized Realms, it
     takes care of computing the actual path on disk based on the server,
     virtual path, and user as is done when opening the Realm.

     @param config A Realm configuration to check the existence of.
     @return true if the Realm file for the given configuration exists on disk, false otherwise.
     */
    public static func fileExists(for config: Configuration) -> Bool {
        return RLMRealm.fileExists(for: config.rlmConfiguration)
    }

    /**
     Deletes the local Realm file and associated temporary files for the given configuration.

     This deletes the ".realm", ".note" and ".management" files which would be
     created by opening the Realm with the given configuration. It does not
     delete the ".lock" file (which contains no persisted data and is recreated
     from scratch every time the Realm file is opened).

     The Realm must not be currently open on any thread or in another process.
     If it is, this will throw the error .alreadyOpen. Attempting to open the
     Realm on another thread while the deletion is happening will block, and
     then create a new Realm and open that afterwards.

     If the Realm already does not exist this will return `false`.

     @param config A Realm configuration identifying the Realm to be deleted.
     @return true if any files were deleted, false otherwise.
     */
    public static func deleteFiles(for config: Configuration) throws -> Bool {
        return try RLMRealm.deleteFiles(for: config.rlmConfiguration)
    }

    // MARK: Internal

    internal var rlmRealm: RLMRealm
    internal init(_ rlmRealm: RLMRealm) {
        self.rlmRealm = rlmRealm
    }
}

// MARK: Sync Subscriptions

extension Realm {
    /**
     Returns an instance of `SyncSubscriptionSet`, representing the active subscriptions
     for this realm, which can be used to add/remove/update and search flexible sync subscriptions.
     Getting the subscriptions from a local or partition-based configured realm will thrown an exception.

     - returns: A `SyncSubscriptionSet`.
     - Warning: This feature is currently in beta and its API is subject to change.
     */
    public var subscriptions: SyncSubscriptionSet {
        return SyncSubscriptionSet(rlmRealm.subscriptions)
    }
}

// MARK: Asymmetric Sync

extension Realm {
    /**
     Creates an Asymmetric object, which will be synced unidirectionally and
     cannot be queried locally. Only objects which inherit from `AsymmetricObject`
     can be created using this method.

     Objects created using this method will not be added to the Realm.

     - warning: This method may only be called during a write transaction.

     - parameter type:   The type of the object to create.
     - parameter value:  The value used to populate the object.
     */
    public func create<T: AsymmetricObject>(_ type: T.Type, value: Any = [String: Any]()) {
        let typeName = (type as AsymmetricObject.Type).className()
        RLMCreateAsymmetricObjectInRealm(rlmRealm, typeName, value)
    }
}

// MARK: Equatable

extension Realm: Equatable {
    /// Returns whether two `Realm` instances are equal.
    public static func == (lhs: Realm, rhs: Realm) -> Bool {
        return lhs.rlmRealm == rhs.rlmRealm
    }
}

// MARK: Notifications

extension Realm {
    /// A notification indicating that changes were made to a Realm.
    @frozen public enum Notification: String {
        /**
         This notification is posted when the data in a Realm has changed.

         `didChange` is posted after a Realm has been refreshed to reflect a write transaction, This can happen when an
         autorefresh occurs, `refresh()` is called, after an implicit refresh from `write(_:)`/`beginWrite()`, or after
         a local write transaction is committed.
         */
        case didChange = "RLMRealmDidChangeNotification"

        /**
         This notification is posted when a write transaction has been committed to a Realm on a different thread for
         the same file.

         It is not posted if `autorefresh` is enabled, or if the Realm is refreshed before the notification has a chance
         to run.

         Realms with autorefresh disabled should normally install a handler for this notification which calls
         `refresh()` after doing some work. Refreshing the Realm is optional, but not refreshing the Realm may lead to
         large Realm files. This is because an extra copy of the data must be kept for the stale Realm.
         */
        case refreshRequired = "RLMRealmRefreshRequiredNotification"
    }
}

/// The type of a block to run for notification purposes when the data in a Realm is modified.
public typealias NotificationBlock = (_ notification: Realm.Notification, _ realm: Realm) -> Void

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private func shouldAsyncOpen(_ configuration: Realm.Configuration,
                             _ downloadBeforeOpen: Realm.OpenBehavior) -> Bool {
    switch downloadBeforeOpen {
    case .never:
        return false
    case .once:
        return !Realm.fileExists(for: configuration)
    case .always:
        return true
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Realm {
    /// Options for when to download all data from the server before opening
    /// a synchronized Realm.
    @frozen public enum OpenBehavior: Sendable {
        /// Immediately return the Realm as if the synchronous initializer was
        /// used. If this is the first time that the Realm has been opened on
        /// this device, the Realm file will initially be empty. Synchronized
        /// Realms will contact the server and download new data in the
        /// background.
        case never
        /// Always open the Realm asynchronously and download all data from the
        /// server before returning the Realm. This mode will fail to open the
        /// Realm if the device is currently offline.
        case always
        /// Open the Realm asynchronously the first time it is opened on the
        /// current device, and then synchronously afterwards. This mode is
        /// suitable if you wish to wait to download the server-side data the
        /// first time your app is launched on each device, but afterwards
        /// support offline launches using the existing local data.
        ///
        /// Note that if .once is used multiple times simultaneously then calls
        /// after the first may see partial local data from the first call and
        /// not wait for the download.
        case once
    }

    /**
     Obtains a `Realm` instance with the given configuration, possibly asynchronously.
     By default this simply returns the Realm instance exactly as if the
     synchronous initializer was used. It optionally can instead open the Realm
     asynchronously, performing all work needed to get the Realm to a usable
     state on a background thread. For local Realms, this means that migrations
     will be run in the background, and for synchronized Realms all data will
     be downloaded from the server before the Realm is returned.
     - parameter configuration: A configuration object to use when opening the Realm.
     - parameter downloadBeforeOpen: When opening the Realm should first download
     all data from the server.
     - throws: An `NSError` if the Realm could not be initialized.
     - returns: An open Realm.
     */
    @MainActor
    public init(configuration: Realm.Configuration = .defaultConfiguration,
                downloadBeforeOpen: OpenBehavior = .never) async throws {
        let scheduler = RLMScheduler.dispatchQueue(.main)
        let rlmRealm = try await openRealm(configuration: configuration, scheduler: scheduler,
                                           actor: MainActor.shared, downloadBeforeOpen: downloadBeforeOpen)
        self = Realm(rlmRealm.wrappedValue)
    }

    /**
     Asynchronously obtains a `Realm` instance isolated to the given Actor.

     Opening a Realm with an actor isolates the Realm to that actor. Rather
     than being confined to the specific thread which the Realm was opened on,
     the Realm can instead only be used from within that actor or functions
     isolated to that actor. Isolating a Realm to an actor also enables using
     ``asyncWrite`` and ``asyncRefresh``.

     All initialization work to prepare the Realm for work, such as creating,
     migrating, or compacting the file on disk, and waiting for synchronized
     Realms to download the latest data from the server is done on a background
     thread and does not block the calling executor.

     When using actor-isolated Realms, enabling struct concurrency checking
     (`SWIFT_STRICT_CONCURRENCY=complete` in Xcode) and runtime data race
     detection (by passing `-Xfrontend -enable-actor-data-race-checks` to the
     compiler) is strongly recommended.

     - parameter configuration: A configuration object to use when opening the Realm.
     - parameter actor: The actor to confine this Realm to. The actor can be
     either a local actor or a global actor. The calling function does not need
     to be isolated to the actor passed in, but if it is not it will not be
     able to use the returned Realm.
     - parameter downloadBeforeOpen: When opening the Realm should first download
     all data from the server.
     - throws: An `NSError` if the Realm could not be initialized.
               `CancellationError` if the task is cancelled.
     - returns: An open Realm.
     */
    public init<A: Actor>(configuration: Realm.Configuration = .defaultConfiguration,
                          actor: A,
                          downloadBeforeOpen: OpenBehavior = .never) async throws {
        let scheduler = RLMScheduler.actor(actor, invoke: actor.invoke, verify: await actor.verifier())
        let rlmRealm = try await openRealm(configuration: configuration, scheduler: scheduler,
                                            actor: actor, downloadBeforeOpen: downloadBeforeOpen)
        self = Realm(rlmRealm.wrappedValue)
    }

#if compiler(<6)
    /**
     Performs actions contained within the given block inside a write transaction.

     This function differs from synchronous ``write`` in that it suspends the
     calling task while waiting for its turn to write rather than blocking the
     thread. In addition, the actual i/o to write data to disk is done by a
     background worker thread. For small writes, using this function on the
     main thread may block the main thread for less time than manually
     dispatching the write to a background thread.

     If the block throws an error, the transaction will be canceled and any
     changes made before the error will be rolled back.

     Only one write transaction can be open at a time for each Realm file. Write
     transactions cannot be nested, and trying to begin a write transaction on a
     Realm which is already in a write transaction will throw an exception.
     Calls to `write` from `Realm` instances for the same Realm file in other
     threads or other processes will block until the current write transaction
     completes or is cancelled.

     Before beginning the write transaction, `asyncWrite` updates the `Realm`
     instance to the latest Realm version, as if `asyncRefresh()` had been called,
     and generates notifications if applicable. This has no effect if the Realm
     was already up to date.

     You can skip notifying specific notification blocks about the changes made
     in this write transaction by passing in their associated notification
     tokens. This is primarily useful when the write transaction is saving
     changes already made in the UI and you do not want to have the notification
     block attempt to re-apply the same changes.

     The tokens passed to this function must be for notifications for this Realm
     which were added on the same actor as the write transaction is being
     performed on. Notifications for different threads cannot be skipped using
     this method.

     - parameter tokens: An array of notification tokens which were returned
                         from adding callbacks which you do not want to be
                         notified for the changes made in this write transaction.

     - parameter block: The block containing actions to perform.
     - returns: The value returned from the block, if any.

     - throws: An `NSError` if the transaction could not be completed successfully.
               `CancellationError` if the task is cancelled.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    @discardableResult
    @_unsafeInheritExecutor
    public func asyncWrite<Result>(_ block: (() throws -> Result)) async throws -> Result {
        guard let actor = rlmRealm.actor as? Actor else {
            fatalError("asyncWrite() can only be called on main thread or actor-isolated Realms")
        }
        return try await withoutActuallyEscaping(block) { block in
            try await Self.asyncWrite(actor: actor, realm: Unchecked(rlmRealm), Unchecked(block)).wrappedValue
        }
    }

    private static func asyncWrite<Result>(actor: isolated any Actor,
                                           realm: Unchecked<RLMRealm>,
                                           _ block: Unchecked<(() throws -> Result)>) async throws
    -> Unchecked<Result> {
        let realm = realm.wrappedValue
        let write = realm.beginAsyncWrite()
        await withTaskCancellationHandler {
            await write.wait()
        } onCancel: {
            actor.invoke { write.complete(true) }
        }

        let ret: Result
        do {
            try Task.checkCancellation()
            ret = try block.wrappedValue()
        } catch {
            if realm.inWriteTransaction { realm.cancelWriteTransaction() }
            throw error
        }

        if realm.inWriteTransaction {
            try await realm.commitAsyncWrite(withGrouping: false)
        }
        return Unchecked(ret)
    }

    /**
     Updates the Realm and outstanding objects managed by the Realm to point to
     the most recent data and deliver any applicable notifications.

     This function should be used instead of synchronous ``refresh`` in async
     functions, as it suspends the calling task (if required) rather than
     blocking.

     - warning: This function is only supported for main thread and
                actor-isolated Realms.
     - returns: Whether there were any updates for the Realm. Note that `true`
                may be returned even if no data actually changed.
     */
    @discardableResult
    @_unsafeInheritExecutor
    public func asyncRefresh() async -> Bool {
        guard rlmRealm.actor as? Actor != nil else {
            fatalError("asyncRefresh() can only be called on main thread or actor-isolated Realms")
        }
        guard let task = RLMRealmRefreshAsync(rlmRealm) else {
            return false
        }
        return await withTaskCancellationHandler {
            await task.wait()
        } onCancel: {
            task.complete(false)
        }
    }

#else // compiler(<6)

    /**
     Performs actions contained within the given block inside a write transaction.

     This function differs from synchronous ``write`` in that it suspends the
     calling task while waiting for its turn to write rather than blocking the
     thread. In addition, the actual i/o to write data to disk is done by a
     background worker thread. For small writes, using this function on the
     main thread may block the main thread for less time than manually
     dispatching the write to a background thread.

     If the block throws an error, the transaction will be canceled and any
     changes made before the error will be rolled back.

     Only one write transaction can be open at a time for each Realm file. Write
     transactions cannot be nested, and trying to begin a write transaction on a
     Realm which is already in a write transaction will throw an exception.
     Calls to `write` from `Realm` instances for the same Realm file in other
     threads or other processes will block until the current write transaction
     completes or is cancelled.

     Before beginning the write transaction, `asyncWrite` updates the `Realm`
     instance to the latest Realm version, as if `asyncRefresh()` had been called,
     and generates notifications if applicable. This has no effect if the Realm
     was already up to date.

     You can skip notifying specific notification blocks about the changes made
     in this write transaction by passing in their associated notification
     tokens. This is primarily useful when the write transaction is saving
     changes already made in the UI and you do not want to have the notification
     block attempt to re-apply the same changes.

     The tokens passed to this function must be for notifications for this Realm
     which were added on the same actor as the write transaction is being
     performed on. Notifications for different threads cannot be skipped using
     this method.

     - parameter tokens: An array of notification tokens which were returned
                         from adding callbacks which you do not want to be
                         notified for the changes made in this write transaction.

     - parameter block: The block containing actions to perform.
     - returns: The value returned from the block, if any.

     - throws: An `NSError` if the transaction could not be completed successfully.
               `CancellationError` if the task is cancelled.
               If `block` throws, the function throws the propagated `ErrorType` instead.
     */
    @discardableResult
    public func asyncWrite<Result>(_isolation actor: isolated any Actor = #isolation, _ block: (() throws -> Result)) async throws -> Result {
        guard rlmRealm.actor != nil else {
            fatalError("asyncWrite() can only be called on main thread or actor-isolated Realms")
        }
        let realm = rlmRealm
        let write = realm.beginAsyncWrite()
        await withTaskCancellationHandler {
            await write.wait()
        } onCancel: {
            actor.invoke { write.complete(true) }
        }

        let ret: Result
        do {
            try Task.checkCancellation()
            ret = try block()
        } catch {
            if realm.inWriteTransaction { realm.cancelWriteTransaction() }
            throw error
        }

        if realm.inWriteTransaction {
            let error = await withCheckedContinuation { continuation in
                realm.commitAsyncWrite(withGrouping: false, completion: continuation.resume)
            }
            if let error {
                throw error
            }
        }
        return ret
    }

    /**
     Updates the Realm and outstanding objects managed by the Realm to point to
     the most recent data and deliver any applicable notifications.

     This function should be used instead of synchronous ``refresh`` in async
     functions, as it suspends the calling task (if required) rather than
     blocking.

     - warning: This function is only supported for main thread and
                actor-isolated Realms.
     - returns: Whether there were any updates for the Realm. Note that `true`
                may be returned even if no data actually changed.
     */
    @discardableResult
    public func asyncRefresh(_isolation: isolated any Actor = #isolation) async -> Bool {
        guard rlmRealm.actor != nil else {
            fatalError("asyncRefresh() can only be called on main thread or actor-isolated Realms")
        }
        guard let task = RLMRealmRefreshAsync(rlmRealm) else {
            return false
        }
        return await withTaskCancellationHandler {
            await task.wait()
        } onCancel: {
            task.complete(false)
        }
    }
#endif // compiler(<6)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
private func openRealm<A: Actor>(configuration: Realm.Configuration,
                                 scheduler: RLMScheduler,
                                 actor: isolated A,
                                 downloadBeforeOpen: Realm.OpenBehavior
) async throws -> Unchecked<RLMRealm> {
    let scheduler = RLMScheduler.actor(actor, invoke: actor.invoke, verify: actor.verifier())
    let rlmConfiguration = configuration.rlmConfiguration

    // If we already have a cached Realm for this actor, just reuse it
    // If this Realm is open but with a different scheduler, open it synchronously.
    // The overhead of dispatching to a different thread and back is more expensive
    // than the fast path of obtaining a new instance for an already open Realm.
    var realm = RLMGetCachedRealm(rlmConfiguration, scheduler)
    if realm == nil, let cachedRealm = RLMGetAnyCachedRealm(rlmConfiguration) {
        try withExtendedLifetime(cachedRealm) {
            realm = try RLMRealm(configuration: rlmConfiguration, confinedTo: scheduler)
        }
    }
    if let realm = realm {
        // This can't be hit on the first open so .once == .never
        if downloadBeforeOpen == .always {
            let task = RLMAsyncDownloadTask(realm: realm)
            try await task.waitWithCancellationHandler()
        }
        return Unchecked(realm)
    }

    // We're doing the first open and hitting the expensive path, so do an async
    // open on a background thread
    let task = RLMAsyncOpenTask(configuration: rlmConfiguration, confinedTo: scheduler,
                                download: shouldAsyncOpen(configuration, downloadBeforeOpen))
    // progress notifications?
    do {
        try await task.waitWithCancellationHandler()
        let realm = task.localRealm!
        task.localRealm = nil
        return Unchecked(realm)
    } catch {
        // Check if the task was cancelled and if so replace the error
        // with reporting cancellation
        try Task.checkCancellation()
        throw error
    }
}

@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
private protocol TaskWithCancellation: Sendable {
    func waitWithCancellationHandler() async throws
    func wait() async throws
    func cancel()
}

@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
extension TaskWithCancellation {
    func waitWithCancellationHandler() async throws {
        do {
            try await withTaskCancellationHandler {
                try await wait()
            } onCancel: {
                cancel()
            }
        } catch {
            // Check if the task was cancelled and if so replace the error
            // with reporting cancellation
            try Task.checkCancellation()
            throw error
        }
    }
}
extension RLMAsyncOpenTask: TaskWithCancellation {}
extension RLMAsyncDownloadTask: TaskWithCancellation {}

@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
internal extension Actor {
    func verifier() -> (@Sendable () -> Void) {
#if compiler(>=5.10)
        // This was made backdeployable in Xcode 15.3
        return {
            self.preconditionIsolated()
        }
#else
        // When possible use the official API for actor checking
        if #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) {
            return {
                self.preconditionIsolated()
            }
        }

        // This exploits a hole in Swift's type system to construct a function
        // which is isolated to the current actor, and then casts away that
        // information. This results in runtime warnings/aborts if it's called
        // from outside the actor when actor data race checking is enabled.
        let fn: () -> Void = { _ = self }
        return unsafeBitCast(fn, to: (@Sendable () -> Void).self)
#endif
    }

    // Asynchronously invoke the given block on the actor. This takes a
    // non-sendable function because the function is invoked on the same actor
    // it was defined on, and just goes through some hops in between.
    nonisolated func invoke(_ fn: @escaping () -> Void) {
        let fn = unsafeBitCast(fn, to: (@Sendable () -> Void).self)
        Task {
            await doInvoke(fn)
        }
    }

    private func doInvoke(_ fn: @Sendable () -> Void) {
        fn()
    }

    // A helper to invoke a regular isolated sendable function with this actor
    func invoke<T: Sendable>(_ fn: @Sendable (isolated Self) async throws -> T) async rethrows -> T {
        try await fn(self)
    }
}

/**
 Objects which can be fetched from the Realm - Object or Projection
 */
public protocol RealmFetchable: RealmCollectionValue {
    /// :nodoc:
    static func className() -> String
}
/// :nodoc:
extension Object: RealmFetchable {}
/// :nodoc:
extension Projection: RealmFetchable {
    /// :nodoc:
    public static func className() -> String {
        return Root.className()
    }
}

/**
 `Logger` is used for creating your own custom logging logic.

 You can define your own logger creating an instance of `Logger` and define the log function which will be
 invoked whenever there is a log message.

 ```swift
 let logger = Logger(level: .all) { level, message in
    print("Realm Log - \(level): \(message)")
 }
 ```

 Set this custom logger as you default logger using `Logger.shared`.

 ```swift
    Logger.shared = inMemoryLogger
 ```

 - note: By default default log threshold level is `.info`, and logging strings are output to Apple System Logger.
*/
public typealias Logger = RLMLogger
extension Logger {
    /**
     Log a message to the supplied level.

     ```swift
     let logger = Logger(level: .info, logFunction: { level, message in
         print("Realm Log - \(level): \(message)")
     })
     logger.log(level: .info, message: "Info DB: Database opened succesfully")
     ```

     - parameter level: The log level for the message.
     - parameter message: The message to log.
     */
    internal func log(level: LogLevel, message: String) {
        self.logLevel(level, message: message)
    }
}
