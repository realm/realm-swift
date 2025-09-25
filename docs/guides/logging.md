# Logging - Swift SDK
You can set or change your app's log level when developing or debugging
your application. You might want to change the log level to log different
amounts of data depending on your development needs.

## Set or Change the Realm Log Level
You can set the level of detail reported by the Realm Swift SDK. Set the
log level for the default logger with `Logger.shared.level`:

```swift
Logger.shared.level = .trace

```

The `RLMLogLevel` enum represents the different levels of logging you can configure.

You can change the log level to increase or decrease verbosity at different
points in your code.
```swift
// Set a log level that isn't too verbose
Logger.shared.level = .warn

// Later, when trying to debug something, change the log level for more verbosity
Logger.shared.level = .trace

```

## Turn Off Logging
The default log threshold level for the Realm Swift SDK is `.info`. This
displays some information in the console. You can disable logging entirely
by setting the log level to `.off`:

```swift
Logger.shared.level = .off

```

## Customize the Logging Function
Initialize an instance of a `Logger` and define the function to use for logging.

```swift
// Create an instance of `Logger` and define the log function to invoke.
let logger = Logger(level: .detail) { level, message in
    // You may pass log information to a logging service, or
    // you could simply print the logs for debugging. Define
    // the log function that makes sense for your application.
    print("REALM DEBUG: \(Date.now) \(level) \(message) \n")
}

```

> Tip:
> To diagnose and troubleshoot errors while developing your application, set the
log level to `debug` or `trace`. For production deployments, decrease the
log level for improved performance.
>

You can set a logger as the default logger for your app with `Logger.shared`.
After you set the default logger, you can change the log level during the app
lifecycle as needed.

```swift
let logger = Logger(level: .info) { level, message in
    // You may pass log information to a logging service, or
    // you could simply print the logs for debugging. Define
    // the log function that makes sense for your application.
    print("REALM DEBUG: \(Date.now) \(level) \(message) \n")
}

// Set a logger as the default
Logger.shared = logger

// After setting a default logger, you can change
// the log level at any point during the app lifecycle
Logger.shared.level = .debug

```
