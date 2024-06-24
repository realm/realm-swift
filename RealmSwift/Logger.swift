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
 Logger.setLogLevel(.info, for: Category.sdk)
 ```

 Read the global log level for a given category.
 ```swift
 let level = Logger.logLevel(for: Category.Storage.all)
 ```

 You can define your own custom logger creating an instance of `Logger` and defining the log function which will be
 invoked whenever there is a log message.

 ```swift
 let logger = Logger(function: { level, category, message in
    print("Realm Log - \(category.rawValue)-\(level): \(message)")
 })
 ```

 Set this custom logger as you default logger using `Logger.shared`. This will replace the default logger.

 ```swift
 Logger.shared = logger
 ```

 - note: By default log threshold level is `.info`, for the log category `.Category.realm`,
         and logging strings are output to Apple System Logger.
 - SeeAlso: `LogCategory`
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
     - parameter category: The log category for the message.
     - parameter message: The message to log.
     */
    internal func log(level: LogLevel, category: LogCategory = Category.realm, message: String) {
        self.log(with: level, category: ObjectiveCSupport.convert(value: category), message: message)
    }

    /**
     Creates a logger with the associated log level, and a logic function to define your own logging logic.

     ```swift
     let logger = Logger(level: .info, category: Category.All, logFunction: { level, category, message in
         print("\(category.rawValue) - \(level): \(message)")
     })
     ```

     - parameter level: The log level to be set for the logger.
     - parameter function: The log function which will be invoked whenever there is a log message.

     - note: This will set the specified log level for the log category `Category.realm`.
     */
    @available(*, deprecated, message: "Use init(function:)")
    public convenience init(level: LogLevel, function: @escaping @Sendable (LogLevel, LogCategory, String) -> Void) {
        self.init(logFunction: { level, category, message in
            function(level, ObjectiveCSupport.convert(value: category), message)
        })
        Logger.setLogLevel(level, for: Category.realm)
    }

    /**
     Creates a logger with a callback, which will be invoked whenever there is a log message.

     ```swift
     let logger = Logger(function: { level, category, message in
         print("\(category.rawValue) - \(level): \(message)")
     })
     ```

     - parameter function: The log function which will be invoked whenever there is a log message.
     */
    public convenience init(function: @escaping @Sendable (LogLevel, LogCategory, String) -> Void) {
        self.init(logFunction: { level, category, message in
            function(level, ObjectiveCSupport.convert(value: category), message)
        })
    }

    /**
     Sets the global log level for a given log category.

     - parameter level: The log level to be set for the logger.
     - parameter category: The log category to be set for the logger, by default it will setup the top Category `Category.realm`

     - note:By setting the log level of a category, it will set all its subcategories log level as well.
     - SeeAlso: `LogCategory`
     */
    public static func setLogLevel(_ level: LogLevel, for category: LogCategory = Category.realm) {
        Logger.__setLevel(level, for: ObjectiveCSupport.convert(value: category))
    }

    /**
     Gets the current global log level of a log category.

     - parameter category: The target log category.

     - returns: The `LogLevel` for the given category.
     - SeeAlso: `LogCategory`
     */
    public static func logLevel(for category: LogCategory) -> LogLevel {
        Logger.__level(for: ObjectiveCSupport.convert(value: category))
    }
}

/// Defines a log category for the Realm `Logger`.
public protocol LogCategory: Sendable {
    /**
     Returns the string represtation of the Log category.

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
public enum Category: String, LogCategory {
    ///  Top level log category for Realm, updating this category level would set all other subcategories too.
    case realm = "Realm"
    /// Log category for all sdk related logs.
    case sdk = "Realm.SDK"
    /// Log category for all app related logs.
    case app = "Realm.App"

    /// :nodoc:
    fileprivate static func fromString(_ string: String) -> LogCategory? {
        if let category = Category(rawValue: string) {
            return category
        } else if let storage = Storage(rawValue: string) {
            return storage
        } else if let sync = Sync(rawValue: string) {
            return sync
        } else if let client = Sync.Client(rawValue: string) {
            return client
        } else {
            return nil
        }
    }

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
    public enum Storage: String, LogCategory {
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
    public enum Sync: String, LogCategory {
        /// Log category for all sync related logs.
        case all = "Realm.Sync"
        /// Log category for all sync server related logs.
        case server = "Realm.Sync.Server"

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
        public enum Client: String, LogCategory {
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

private extension ObjectiveCSupport {

    /// Converts a Swift category `LogCategory` to an Objective-C `RLMLogCategory.
    /// - Parameter value: The `LogCategory`.
    /// - Returns: Conversion of `value` to its Objective-C representation.
    static func convert(value: LogCategory) -> RLMLogCategory {
        switch value {
        case Category.realm:
            return RLMLogCategory.realm
        case Category.sdk:
            return RLMLogCategory.realmSDK
        case Category.app:
            return RLMLogCategory.realmApp
        case Category.Storage.all:
            return RLMLogCategory.realmStorage
        case Category.Storage.transaction:
            return RLMLogCategory.realmStorageTransaction
        case Category.Storage.query:
            return RLMLogCategory.realmStorageQuery
        case Category.Storage.object:
            return RLMLogCategory.realmStorageObject
        case Category.Storage.notification:
            return RLMLogCategory.realmStorageNotification
        case Category.Sync.all:
            return RLMLogCategory.realmSync
        case Category.Sync.Client.all:
            return RLMLogCategory.realmSyncClient
        case Category.Sync.Client.session:
            return RLMLogCategory.realmSyncClientSession
        case Category.Sync.Client.changeset:
            return RLMLogCategory.realmSyncClientChangeset
        case Category.Sync.Client.network:
            return RLMLogCategory.realmSyncClientNetwork
        case Category.Sync.Client.reset:
            return RLMLogCategory.realmSyncClientReset
        case Category.Sync.server:
            return RLMLogCategory.realmSyncServer
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
        case RLMLogCategory.realmSDK:
            return Category.sdk
        case RLMLogCategory.realmApp:
            return Category.app
        case RLMLogCategory.realmStorage:
            return Category.Storage.all
        case RLMLogCategory.realmStorageTransaction:
            return Category.Storage.transaction
        case RLMLogCategory.realmStorageQuery:
            return Category.Storage.query
        case RLMLogCategory.realmStorageObject:
            return Category.Storage.object
        case RLMLogCategory.realmStorageNotification:
            return Category.Storage.notification
        case RLMLogCategory.realmSync:
            return Category.Sync.all
        case RLMLogCategory.realmSyncClient:
            return Category.Sync.Client.all
        case RLMLogCategory.realmSyncClientSession:
            return Category.Sync.Client.session
        case RLMLogCategory.realmSyncClientChangeset:
            return Category.Sync.Client.changeset
        case RLMLogCategory.realmSyncClientNetwork:
            return Category.Sync.Client.network
        case RLMLogCategory.realmSyncClientReset:
            return Category.Sync.Client.reset
        case RLMLogCategory.realmSyncServer:
            return Category.Sync.server
        default:
            fatalError()
        }
    }
}
