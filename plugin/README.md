# Realm Plugin

The Realm Plugin for Xcode adds several useful features for developing with Realm:

1. A LLDB script which adds support for inspecting the property values of
   persisted RLMObjects in the debugger pane.
2. File templates for RLMObject subclasses.
3. A menu item in Xcode's 'File' menu to quickly launch the Realm Browser.
   Note that this item will only appear in Xcode 7 and in unsigned versions of
   Xcode 8 or later (not recommended).

To install the Realm Plugin, open `RealmPlugin.xcodeproj` and Build. This will
prompt for your password. After building the plugin, restart Xcode.
