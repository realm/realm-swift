////////////////////////////////////////////////////////////////////////////
//
// Copyright 2023 Realm Inc.
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
 `Logger` is a base class for creating your own custom logging logic.

 Define your custom logger by subclassing `Logger` and override the `doLog(level:message:)`
 function to implement your custom logging logic.

 ```swift
 final class InMemoryLogger: Logger {
     var logs: String = ""

     override func doLog(level: LogLevel, message: String) {
         logs += "Realm Logger: \(Date.now): \(level.logLevel) \(message)"
     }
 }
 ```

 Set this custom logger as you default logger using `Logger.setDefaultLogger()`.

 ```swift
    let inMemoryLogger = InMemoryLogger()
    Logger.setDefaultLogger(inMemoryLogger)
 ```
*/
public typealias Logger = RLMLogger
extension Logger {
    /**
     Log a message to the supplied level.

     ```swift
     let inMemoryLogger = InMemoryLogger()
     inMemoryLogger.log(level: .info, message: "Info DB: Database opened succesfully")
     ```

     - parameter level: The log level for the message.
     - parameter message: The message to log.
     */
    public func log(level: LogLevel, message: String) {
        self.logLevel(level, message: message)
    }

    // MARK: Logger class functions
    /**
     The logging threshold level used by the global logger.

     By default logging strings are output to Apple System Logger. Set a default `Logger` to perform custom logging logic instead.

     - warning: Setting a global log threshold level after setting a custom logger will override any level threshold set by any default logger.
     Logger will return log information, with associated log level, lower or equal to the global log level in that case.
     */
    public static var logLevel: LogLevel {
        get {
            RLMLogger.logLevel()
        } set {
            RLMLogger.setLogLevel(newValue)
        }
    }
}
