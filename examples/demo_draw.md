##The demo app is a OS X and iOS drawing app.

To see how the synchronization is done, you can either run in the same local network:**
	
	* the OS X app on 2 computers 
	* the iOS app on 2 simulators
	* the iOS app on the phone and in the simulator 

The OS X app and the iOS app do not share the same schema, so you cannot run them together.

**Run the demo:**

1. Start the server, according to the run_demo_server.md document. Use the external ip if running the demo over the network.

2. Run the app

You need to set the correct server hostname and port.
The default server port is 7800.
eg of a realm url: `"realm://127.0.0.1:7800/draw"`. 

For the OS X app, open the xcode project in `examples/osx/objc`. Edit the `Draw/DrawView.m` with the correct server hostname and port.
Then run the "Draw" scheme.

For the iOS app, open the xcode project in `examples/ios/objc`. Edit the `Draw/DrawView.m` with the correct server hostname and port.
Then run the "Draw" scheme. You can run it in a simulator, for the iPhone 6s Plus for example.

The Realm frameworks should already be included in the projects, so if you keep the folder structure of the archive no change should be required.

When you draw in one app, the other app will receive the changes in real time.

If you want to start from scratch, you should clean up the server file and "Reset the contents and settings" on the simulator.