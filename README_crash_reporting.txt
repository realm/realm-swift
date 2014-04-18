What's required otherwise in terms of build, setup documentation, download
of examples etc?
The crash reporter 'should' largely be invisible to app developers that make use of TightDB.  With the recent change from linking with libc++.dylib to libstdc++.6.dylib, this removed the requirement of having to explicitly link libstdc++.dylib.  The app should add "-ObjC" and "-all_load" to "Other Linker Flags" in Xcode build settings.  This is because the Apigee code uses categories fairly extensively.

How is crash reporting enabled/disabled?
By default, it's enabled with the changes that I made.  I modified "TDBContext" (and will need to do the same with "TDBSmartContext") class methods that retrieve the context to initialize the crash reporter.  The code is also surrounded by preprocessor macros that can be easily used to disable all of the crash reporting completely.  TDBContext changes calls into TDBCrashReportingAgentLauncher's "startCrashReporter" to do the heavy-lifting of initializing the crash reporter.  This code looks for a key named "TDBDisableCrashReporting" as a boolean property.  If this key is found in the app's Info.plist file and has a TRUE value, then it DISABLES the crash reporting (by never initializing it).  Having a value of FALSE, or not having the key at all, will cause the crash reporting to be enabled (as it is by default).

Access to server of logs?
The Apigee app identifiers (similar to credentials) can be found in the top (lines 29 & 30) of TDBCrashReportingAgentLauncher.mm (a new source file).

I would encourage you to go to https://apigee.com/appservices and click on the "sign up" (it's free, and they don't spam you too much).  When you sign up, it'll ask you to create an org name ("TightDB" or "Realm") and an app.  In our case, we're not using the SDK in an "app", but in a framework, but the name really only has to make sense to you.  You can name the org name and app name whatever you like (Apigee doesn't really care).  Then you can change the hard-coded values in TDBCrashReportingAgentLauncher.mm to match the values that you set up in Apigee's portal.  Once you're set up with Apigee, you use that same url (above) to login to the Apigee portal.  Once inside the Apigee portal, look for the "MONITORING" section in the left-hand navigation bar of the portal.  Under that section, you'll see "App Usage" (high-level stats about sessions), "Errors & Crashes" (this is the part that's relevant for crash reporting!), and "API Performance" (network perf stats).

Paul, could you please describe the needed steps to completely integrate
this? (release_note.md update, technote describing this feature?)
I'll add all of this documentation to a file also.

? Can you please provide a test example? And describe how to get and use
the crash-report?
I made some changes to the Stocks demo app, so that it prompts the user whether to force a crash (to test out the crash reporting functionality) when you tap on the "Chart" button for a stock.

? How does the crash reporter work (high level)?
The Apigee code makes use of PLCrashReporter.  PLCrashReporter registers itself as an exception handler and gets called (since it registered itself as an exception handler) when a crash is happening. PLCrashReporter quickly and carefully gathers up information about the machine type, OS details, registers, and threads.  It writes all of this data out in a binary format to disk.  NO REPORTING OF THE CRASH HAS OCCURRED AT THIS POINT IN TIME.  The crash report is simply sitting in a file on the device (in the app's sandbox).  When the app is RESTARTED, the Apigee code looks for a crash report.  If it finds one, it reads it (deletes the file), reformats it as an ASCII report and transmits it to the Apigee portal.  After a certain number of minutes (as short as 2, as long as 15 or 20), the email address that was registered on the Apigee portal should receive a system generated email notifying them that a crash occurred (that they received a crash report). You can then go to the Apigee portal and find and view the crash report online.

? How much bigger does it make the lib?
Quite a bit bigger, even though I pared down the Apigee client SDK significantly.  Currently, the Tightdb.framework is 12.5 MB in size.  Adding in the Apigee library (that also contains the PLCrashReporter), the Tightdb.framework grows to 28.8 MB. I wouldn't be too concerned about it because the run-time footprint is pretty small.

? What else should we know?
The Apigee code doesn't even try to initialize PLCrashReporter if the app is running under control of Xcode. Why? Xcode interferes with crash detection.

The crash reports that get uploaded to Apigee are NOT SYMBOLICATED.  In order to symbolicate a crash report, you need to have the corresponding .dSYM that was generated when the app was built (the specific one, not just any one you might have lying around). Some crashes can be meaningfully deciphered even without being symbolicated, and others cannot.