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

 - note: By default default log threshold level is `.warn`, and logging strings are output to Apple System Logger.
*/
class Logger {
    // MARK: Private
    private let _rlmLogger: RLMLogger
    private init(rlmLogger: RLMLogger) {
        self._rlmLogger = rlmLogger
    }

    /**
     Creates a  logger with the associated log level and the logic function to define your own logging logic..

     - parameter level: The log level to be set for the logger.
     - parameter logFunction: The log function which will be invoked whenever there is a log message.
     */
    public convenience init(level: LogLevel, logFunction: @escaping (LogLevel, String) -> Void) {
        let rlmLogger = RLMLogger(level: level, logFunction: logFunction)
        self.init(rlmLogger: rlmLogger)
    }

    /**
     The logging threshold level used by the logger.
     */
    public var level: LogLevel {
        get {
            _rlmLogger.level
        } set {
            _rlmLogger.level = newValue
        }
    }

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
    public func log(level: LogLevel, message: String) {
        _rlmLogger.logLevel(level, message: message)
    }

    // MARK: Logger class functionss

    /**
    The current default logger.
     */
    public class var shared: Logger {
        get {
            Logger(rlmLogger: RLMLogger.default)
        } set {
            RLMLogger.default = newValue._rlmLogger
        }
    }
}
