##The demo app is an iOS drawing app.

This file describes the steps you have to take to run the demo app.

demo_using_framework.md describes the steps you have to take to included synchronized Realms in your app.

demo_server.md describes the steps needed to start the server on a OS X machine.

**Run the demo:**
For the demo you will need an iPhone and a OS X machine connected to the same local network.
1. Find out the ip your computer has in the local network.
2. Start the server, according to the run_demo_server.md document. Use the ip you have previously identified.

3. Run the app in the simulator.

You need to set the same server ip and port that you started the server with in the realm url: `"realm://serverip:port/draw"`
eg of a realm url: `"realm://127.0.0.1:7800/draw"`. 

Open the xcode project in `examples/ios/objc`. Edit the `Draw/AppDelegate.m` with the correct realm url.
Then run the "Draw" scheme. You can run it in a simulator, for the iPhone 6s Plus for example.

Click on the Realm.framework under Frameworks and update its path to the framwork in the archive, `framework/ios/Realm.framework` for the iOS app. The path was also added to the framework search path, so you should not need to do additional changes if you keep the folder structure of the archive.

After starting the app in the simulator, you can draw something and check that the server log changes.

Then you can also load the app on an iPhone connected to the same network. When you draw something on one of them, the other will be updated in Real time.

You can use the app on several devices, but be aware that combining an iPhone with an iPad was not tested.

If you want to start from scratch, you should clean up the server folder( the one you gave as a parameter when you started the server ), restart the server and "Reset the contents and settings" on the simulator.
