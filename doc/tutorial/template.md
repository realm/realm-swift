* Realm Objective-C Interface

Realm is a fast embedded database that integrates transparently into Objective-C. It provides the full benefits of a database, but with a much lower memory footprint and higher performance than native data structures.

Building an iOS app with Realm couldn't be simpler. This article will cover the core concepts.

** Main Classes

<code>RLMRealm</code>, <code>RLMTable</code> and <code>RLMTransactionManager</code> are the main classes you'll encounter while working with Realm.

** Defining a Data Model

Realm data models fully embrace Objective-C and are defined using traditional <code>NSObject</code> classes with <code>@properties</code>. Just subclass <code>RLMRow</code> to create your Realm data model objects:

@@example declare_object @@

See <a href="#">Building a Data Model</a> for more advanced usage examples.

** RLMRealm

The <code>RLMRealm</code> class is the main way to interact with a realm. It's how tables are created and extracted:

@@example setup_realm @@

Realms are read-only and can only be created on the main thread, unless created through a transaction manager.

See the <code>RLMRealm</code> <a href="#">documentation</a> for more details.

** Transaction Manager

The <code>RLMTransactionManager</code> class is responsible for all write transactions:

@@example add_row @@

as well as all read transactions performed outside the main thread:

@@example bg_read @@

These transactions are run on the current thread. As the previous example demonstrates, <code>RLMTable</code>s support fast enumeration.

See the <code>RLMTransactionManager</code> <a href="#">documentation</a> for more details.

** Listening to Changes

Though Realm is extremely fast, it isn't instantaneous. Realm sends notifications to broadcast when a write transaction has completed. These notifications can be observed through the <code>NSNotificationCenter</code>:

@@example setup_notifications @@

** Background Operations

Inserting large amounts of data into your application has never been easier. Realm is designed to work with the tools you already know like Grand Central Dispatch and <code>NSOperationQueue</code>s. Here's an example importing a million objects while keeping an app responsive and still allowing high-priority writes on the main thread:

@@example bg_add @@

** Querying

With support for <code>NSPredicate</code>s and blazing fast performance, Realm's querying interface really shines.

@@example query @@

See the <code>RLMTable</code> <a href="#">documentation</a> for more information on what's possible with tables in Realm.

** Next Steps

This document just scratches the surface of Realm is capable of. Here are some resources available for more information:

<ol>
    <li><a href="#">Realm Objective-C Documentation</a></li>
    <li><a href="#">Realm Objective-C Tutorials</a></li>
    <li><a href="#">Realm on GitHub</a></li>
    <li><a href="#">Realm on StackOverflow</a></li>
    <li><a href="mailto:support@realm.io">support@realm.io</a></li>
</ol>
