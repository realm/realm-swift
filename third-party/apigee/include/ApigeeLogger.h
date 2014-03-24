//
//  ApigeeLogger.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

/*!
 @abstract The logging level to indicate how much or little logging is captured
 @constant kApigeeLogLevelVerbose verbose (most voluminous and detailed log level; includes all)
 @constant kApigeeLogLevelDebug debug (includes debug, info, warning, error, and assert)
 @constant kApigeeLogLevelInfo info (includes info, warning, error, and assert)
 @constant kApigeeLogLevelWarn warning (includes warning, error, and assert)
 @constant kApigeeLogLevelError error (includes error and assert)
 @constant kApigeeLogLevelAssert assert/critical (least voluminous; most terse log level)
 */
typedef enum {
    kApigeeLogLevelVerbose = 2,
    kApigeeLogLevelDebug = 3,
    kApigeeLogLevelInfo = 4,
    kApigeeLogLevelWarn = 5,
    kApigeeLogLevelError = 6,
    kApigeeLogLevelAssert = 7
} ApigeeLogLevel;


/*!
 @class ApigeeLogger
 @abstract ApigeeLogger handles all logging and error reporting functionality
 */
@interface ApigeeLogger : NSObject

/*!
 @internal
 */
+ (int) aslLevel:(ApigeeLogLevel) level;

/*!
 @internal
 */
+ (NSString *) aslAppSenderKey;

/*!
 @internal
 */
+ (NSString *) executableName;


/*!
 @abstract Logs a critical error
 @param tag Tag to use to identify component or subsystem where error occurred
 @param format Format string for error message (with 0 or more arguments)
 */
+ (void) assert:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(2, 3);

/*!
 @abstract Logs an error
 @param tag Tag to use to identify component or subsystem where error occurred
 @param format Format string for error message (with 0 or more arguments)
 */
+ (void) error:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(2, 3);

/*!
 @abstract Logs a message with log level of Warning
 @param tag Tag to use to identify component or subsystem where message occurred
 @param format Format string for message (with 0 or more arguments)
 */
+ (void) warn:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(2, 3);

/*!
 @abstract Logs a message with log level of Info
 @param tag Tag to use to identify component or subsystem where message occurred
 @param format Format string for message (with 0 or more arguments)
 */
+ (void) info:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(2, 3);

/*!
 @abstract Logs a message with log level of Debug
 @param tag Tag to use to identify component or subsystem where message occurred
 @param format Format string for message (with 0 or more arguments)
 */
+ (void) debug:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(2, 3);

/*!
 @abstract Logs a message with log level of Verbose
 @param tag Tag to use to identify component or subsystem where message occurred
 @param format Format string for message (with 0 or more arguments)
 */
+ (void) verbose:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(2, 3);

@end

@interface ApigeeLogger (MacroSupport)

/*!
 @abstract Logs a critical error from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where error occurred
 @param format Format string for error message (with 0 or more arguments)
 */
+ (void) assertFrom:(const char *) function tag:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(3, 4);

/*!
 @abstract Logs an error from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where error occurred
 @param format Format string for error message (with 0 or more arguments)
 */
+ (void) errorFrom:(const char *) function tag:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(3, 4);

/*!
 @abstract Logs a message with log level of Warning from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where message occurred
 @param format Format string for message (with 0 or more arguments)
 */
+ (void) warnFrom:(const char *) function tag:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(3, 4);

/*!
 @abstract Logs a message with log level of Info from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where message occurred
 @param format Format string for message (with 0 or more arguments)
 */
+ (void) infoFrom:(const char *) function tag:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(3, 4);

/*!
 @abstract Logs a message with log level of Debug from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where message occurred
 @param format Format string for message (with 0 or more arguments)
 */
+ (void) debugFrom:(const char *) function tag:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(3, 4);

/*!
 @abstract Logs a message with log level of Verbose from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where message occurred
 @param format Format string for message (with 0 or more arguments)
 */
+ (void) verboseFrom:(const char *) function tag:(NSString *) tag format:(NSString *) format, ... NS_FORMAT_FUNCTION(3, 4);

/*!
 @abstract Logs a critical error from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where error occurred
 @param message The message to log
 */
+ (void) assertFrom:(const char *) function tag:(NSString *) tag message:(NSString *) message;

/*!
 @abstract Logs an error from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where error occurred
 @param message The message to log
 */
+ (void) errorFrom:(const char *) function tag:(NSString *) tag message:(NSString *) message;

/*!
 @abstract Logs a message with log level of Warning from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where message occurred
 @param message The message to log
 */
+ (void) warnFrom:(const char *) function tag:(NSString *) tag message:(NSString *) message;

/*!
 @abstract Logs a message with log level of Info from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where message occurred
 @param message The message to log
 */
+ (void) infoFrom:(const char *) function tag:(NSString *) tag message:(NSString *) message;

/*!
 @abstract Logs a message with log level of Debug from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where message occurred
 @param message The message to log
 */
+ (void) debugFrom:(const char *) function tag:(NSString *) tag message:(NSString *) message;

/*!
 @abstract Logs a message with log level of Verbose from a function or method
 @param function Name of the function or method where error occurred
 @param tag Tag to use to identify component or subsystem where message occurred
 @param message The message to log
 */
+ (void) verboseFrom:(const char *) function tag:(NSString *) tag message:(NSString *) message;

@end


#define ApigeeLogAssert(TAG, ...)  \
[ApigeeLogger assertFrom:__func__ tag:TAG format:__VA_ARGS__]

#define ApigeeLogError(TAG, ...)  \
[ApigeeLogger errorFrom:__func__ tag:TAG format:__VA_ARGS__]

#define ApigeeLogWarn(TAG, ...)  \
[ApigeeLogger warnFrom:__func__ tag:TAG format:__VA_ARGS__]

#define ApigeeLogInfo(TAG, ...)  \
[ApigeeLogger infoFrom:__func__ tag:TAG format:__VA_ARGS__]

#define ApigeeLogDebug(TAG, ...)  \
[ApigeeLogger debugFrom:__func__ tag:TAG format:__VA_ARGS__]

#define ApigeeLogVerbose(TAG, ...)  \
[ApigeeLogger verboseFrom:__func__ tag:TAG format:__VA_ARGS__]


// Use these variants when the logging content is a single NSString
#define ApigeeLogAssertMessage(TAG, MESSAGE)  \
[ApigeeLogger assertFrom:__func__ tag:TAG message:MESSAGE]

#define ApigeeLogErrorMessage(TAG, MESSAGE)  \
[ApigeeLogger errorFrom:__func__ tag:TAG message:MESSAGE]

#define ApigeeLogWarnMessage(TAG, MESSAGE)  \
[ApigeeLogger warnFrom:__func__ tag:TAG message:MESSAGE]

#define ApigeeLogInfoMessage(TAG, MESSAGE)  \
[ApigeeLogger infoFrom:__func__ tag:TAG message:MESSAGE]

#define ApigeeLogDebugMessage(TAG, MESSAGE)  \
[ApigeeLogger debugFrom:__func__ tag:TAG message:MESSAGE]

#define ApigeeLogVerboseMessage(TAG, MESSAGE)  \
[ApigeeLogger verboseFrom:__func__ tag:TAG message:MESSAGE]

