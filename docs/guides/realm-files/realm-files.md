# Work with Realm Files - Swift SDK
A **realm** is the core data structure used to organize data in
Realm. A realm is a collection of the objects that you use
in your application, called Realm objects, as well as additional metadata
that describe the objects. To learn how to define a Realm object, see
Define an Object Model.

## Realm Files
Realm stores a binary encoded version of every object and type in a
realm in a single `.realm` file. The file is located at a specific
path that you can define when you open the
realm. You can open, view, and edit the contents of these files with
Realm Studio.

### In-Memory Realms
You can also open a realm entirely in memory, which does not create a `.realm`
file or its associated auxiliary files. Instead the SDK stores objects in memory
while the realm is open and discards them immediately when all instances are
closed.

> See:
> To open an in-memory realm, refer to Open an In-Memory Realm.
>

### Default Realm
Calling `Realm()` or
`RLMRealm` opens the default realm.
This method returns a realm object that maps to a file named
`default.realm`. You can find this file:

- iOS: in the Documents folder of your app
- macOS: in the Application Support folder of your app

> See:
> To open a default realm, refer to Open a Default Realm or Realm at a File URL.
>

### Auxiliary Realm Files
Realm creates additional files for each realm:

- **realm files**, suffixed with "realm", e.g. default.realm:
contain object data.
- **lock files**, suffixed with "lock", e.g. default.realm.lock:
keep track of which versions of data in a realm are
actively in use. This prevents realm from reclaiming storage space
that is still used by a client application.
- **note files**, suffixed with "note", e.g. default.realm.note:
enable inter-thread and inter-process notifications.
- **management files**, suffixed with "management", e.g. default.realm.management:
internal state management.

Deleting these files has important implications.
For more information about deleting `.realm` or auxiliary files, see:
Delete a Realm

## Find a Realm File Path
The realm file is located at a specific path that you can optionally define
when you open the realm.

```swift
// Get on-disk location of the default Realm
let realm = try! Realm()
print("Realm is located at:", realm.configuration.fileURL!)
```

> See:
> To open a realm at a specific path, refer to Open a Default Realm or Realm at a File URL.
>
