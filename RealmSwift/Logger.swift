////////////////////////////////////////////////////////////////////////////
//
// Copyright 2024 Realm Inc.
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

/**
 Global logger class used by all Realm components.

 Set the global log level for a given category.
 ```swift
 Logger.set(level: .info, for: Category.sdk)
 ```

 Read the global log level for a given category.
 ```swift
 let level = Logger.logLevel(for: Category.Storage.all)
 ```

 By default messages are logged to `NSLog` at the `.info` log level. You can
 remove the default logger by calling `Logger.removeAll()`. You can add your own
 custom logger by calling `Logger.add()`:

 ```swift
 Logger.add { level, category, message in
     print("Realm Log - \(category.rawValue)-\(level): \(message)")
 }
 ```

 Multiple logger callbacks can be registered at once. All will share the same log levels.
*/
public typealias Logger = RLMLogger
extension Logger {
    /**
     Log a message to the supplied level.

     ```swift
     Logger.log(.info, "DB: Database opened succesfully")
     ```
     */
    internal static func log(_ level: LogLevel, _ message: String) {
        RLMLogRaw(level, message)
    }

    /**
     Sets the global log level for a given log category.

     The registered callbacks will not be called for messages with log levels
     below the log level set for the category.

     The `Category.realm`, `Category.Storage.all`, `Category.Sync.all`, and
     `Category.Sync.Client.all` categories are parent categories that set the
     log level for all child categories. These can be used to quickly set the
     log level for all messages logged by Realm (or all Sync messages).

     - parameter level: The log level to be set for the category.
     - parameter category: The log category to update. By default all categories will be updated.
     - SeeAlso: ``LogCategory``
     */
    public static func set(level: LogLevel, for category: LogCategory = Category.realm) {
        Logger.__setLevel(level, for: ObjectiveCSupport.convert(value: category))
    }

    /**
     Gets the current global log level of a log category.

     - parameter category: The target log category.
     - returns: The `LogLevel` for the given category.
     - SeeAlso: `LogCategory`
     */
    public static func logLevel(for category: LogCategory = Category.realm) -> LogLevel {
        Logger.__level(for: ObjectiveCSupport.convert(value: category))
    }

    /// A logger callback function that can be passed to add(logFunction:).
    /// This function may be called from multiple threads concurrently and is
    /// responsible for any synchronization that may require.
    public typealias LogCallback = @Sendable (LogLevel, LogCategory, String) -> Void

    /// A token which can optionally be used to unregister a logger callback.
    public typealias Token = RLMLoggerToken

    /**
     Registers a new logger callback function.

     The logger callback function will be invoked each time a message is logged
     with a log level greater than or equal to the current log level set for the
     message's category. The log function may be concurrently invoked from
     multiple threads.

     This function is thread-safe and can be called at any time, including from
     within other logger callbacks. It is guaranteed to work even if called
     concurrently with logging operations on another thread, but whether or not
     those operations are reported to the callback is left unspecified.

     This method returns a token which can be used to unregister the callback.
     Unlike notification tokens, storing this token is optional. If the token is
     destroyed without `invalidate` being called, it will be impossible to
     unregister the callback other than with `Logger.removeAll()` or
     `Logger.resetToDefault()`.
     */
    @discardableResult
    public static func add(logFunction: @escaping LogCallback) -> RLMLoggerToken {
        Self.__addLogFunction { level, category, message in
            logFunction(level, ObjectiveCSupport.convert(value: category), message)
        }
    }
}

/// Defines a log category for the Realm `Logger`.
public protocol LogCategory: Sendable {
    /**
     Returns the string representation of the Log category.

     - returns: A string representing the log category.
     - SeeAlso: `LogCategory`
     */
    var rawValue: String { get }
}

/**
 Category hierarchy:
 ```
  Realm
  ├─► Storage
  │   ├─► Transaction
  │   ├─► Query
  │   ├─► Object
  │   └─► Notification
  ├─► Sync
  │   ├─► Client
  │   │   ├─► Session
  │   │   ├─► Changeset
  │   │   ├─► Network
  │   │   └─► Reset
  │   └─► Server
  ├─► App
  └─► Sdk
 ```
*/
public enum Category: String, LogCategory, CaseIterable {
    ///  Top level log category for all messages. Setting the log level for this category updates all other categories as well.
    case realm = "Realm"
    /// Log category for things logged by the Realm Swift SDK.
    case sdk = "Realm.SDK"
    /// Log category for the App type. This includes al HTTP(s) requests made to Atlas, but does not include sync.
    case app = "Realm.App"

    /**
     Log category for all storage related logs.

     Category hierarchy:
     ```
      Storage
      ├─► Transaction
      ├─► Query
      ├─► Object
      └─► Notification
     ```
    */
    public enum Storage: String, LogCategory, CaseIterable {
        /// Log category for all database related logs.
        case all = "Realm.Storage"
        /// Log category for all database transaction related logs.
        case transaction = "Realm.Storage.Transaction"
        /// Log category for all database queries related logs.
        case query = "Realm.Storage.Query"
        /// Log category for all database object related logs.
        case object = "Realm.Storage.Object"
        /// Log category for all database notification related logs.
        case notification = "Realm.Storage.Notification"
    }

    /**
     Log category for all sync related logs.

     Category hierarchy:
     ```
      Sync
      ├─► Client
      │   ├─► Session
      │   ├─► Changeset
      │   ├─► Network
      │   └─► Reset
      └─► Server
     ```
     */
    public enum Sync: String, LogCategory, CaseIterable {
        /// Log category for all sync related logs.
        case all = "Realm.Sync"
        /// Log category for all sync server related logs.
        case server = "Realm.Sync.Server"

        /**
         Log category for all storage related logs.

         Category hierarchy:
         ```
         Client
          ├─► Session
          ├─► Changeset
          ├─► Network
          └─► Reset
         ```
         */
        public enum Client: String, LogCategory, CaseIterable {
            /// Log category for all sync client related logs.
            case all = "Realm.Sync.Client"
            /// Log category for all sync client session related logs.
            case session = "Realm.Sync.Client.Session"
            /// Log category for all sync client changeset related logs.
            case changeset = "Realm.Sync.Client.Changeset"
            /// Log category for all sync client network related logs.
            case network = "Realm.Sync.Client.Network"
            /// Log category for all sync client reset related logs.
            case reset = "Realm.Sync.Client.Reset"
        }
    }
}

public extension ObjectiveCSupport {
    /// Converts a Swift category `LogCategory` to an Objective-C `RLMLogCategory.
    /// - Parameter value: The `LogCategory`.
    /// - Returns: Conversion of `value` to its Objective-C representation.
    static func convert(value: LogCategory) -> RLMLogCategory {
        switch value {
        case Category.realm:
            return RLMLogCategory.realm
        case Category.sdk:
            return RLMLogCategory.SDK
        case Category.app:
            return RLMLogCategory.app
        case Category.Storage.all:
            return RLMLogCategory.storage
        case Category.Storage.transaction:
            return RLMLogCategory.storageTransaction
        case Category.Storage.query:
            return RLMLogCategory.storageQuery
        case Category.Storage.object:
            return RLMLogCategory.storageObject
        case Category.Storage.notification:
            return RLMLogCategory.storageNotification
        case Category.Sync.all:
            return RLMLogCategory.sync
        case Category.Sync.Client.all:
            return RLMLogCategory.syncClient
        case Category.Sync.Client.session:
            return RLMLogCategory.syncClientSession
        case Category.Sync.Client.changeset:
            return RLMLogCategory.syncClientChangeset
        case Category.Sync.Client.network:
            return RLMLogCategory.syncClientNetwork
        case Category.Sync.Client.reset:
            return RLMLogCategory.syncClientReset
        case Category.Sync.server:
            return RLMLogCategory.syncServer
        default:
            fatalError()
        }
    }

    /// Converts an Objective-C category `RLMLogCategory` to a Swift `LogCategory.
    /// - Parameter value: The `RLMLogCategory`.
    /// - Returns: Conversion of `value` to its Swift representation.
    static func convert(value: RLMLogCategory) -> LogCategory {
        switch value {
        case RLMLogCategory.realm:
            return Category.realm
        case RLMLogCategory.SDK:
            return Category.sdk
        case RLMLogCategory.app:
            return Category.app
        case RLMLogCategory.storage:
            return Category.Storage.all
        case RLMLogCategory.storageTransaction:
            return Category.Storage.transaction
        case RLMLogCategory.storageQuery:
            return Category.Storage.query
        case RLMLogCategory.storageObject:
            return Category.Storage.object
        case RLMLogCategory.storageNotification:
            return Category.Storage.notification
        case RLMLogCategory.sync:
            return Category.Sync.all
        case RLMLogCategory.syncClient:
            return Category.Sync.Client.all
        case RLMLogCategory.syncClientSession:
            return Category.Sync.Client.session
        case RLMLogCategory.syncClientChangeset:
            return Category.Sync.Client.changeset
        case RLMLogCategory.syncClientNetwork:
            return Category.Sync.Client.network
        case RLMLogCategory.syncClientReset:
            return Category.Sync.Client.reset
        case RLMLogCategory.syncServer:
            return Category.Sync.server
        default:
            fatalError()
        }
    }
}
