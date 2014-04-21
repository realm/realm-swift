* Realm Objective C Interface

This short tutorial to Realm will introduce you to
commonly used features of Realm. Please refer to the
<a href="http://www.tightdb.com/documentation/1/Reference/">reference documentation</a>
for further details.

Realm is a fast embedded database that integrates transparently
into Objective C. It gives you the full benefits of a database, but
with a much lower memory footprint and higher performance than native
data structures.

Realm data structures are represented by tables with typed and
untyped columns. A column in a table can be of any of the following
column types: Integers, Booleans, Floats, Doubles, Strings, Dates,
Binary blobs, and Tables. Moreover, columns in a table can be of the
type Mixed which means that the values can be of any support type.

The core classes of Realm are <code>RLMTable</code>,
<code>RLMContext</code>, and <code>RLMTransaction</code>. Tables are where
data is stored, while contexts can be used to work with
persistent data (on disk). Tables within a context can only the access in
a transactional manner, and Realm distinguish between read and write access.

** Executing the tutorial

While you walk through the tutorial below you may find it beneficial to actually execute the code.
The source code for the tutorial is <a href="http://www.tightdb.com/downloads&/tutorial-ios.zip">available</a>
as an iOS project.

** Creating tables

First, let's create a table with 2 columns using the typed table interface:

@@example create_table @@

The <code>REALM_TABLE_2</code> is a macro which creates the appropriate Objective C classes
including <code>RLMDemoTable</code>.

The above code creates a Realm table type with 2 typed columns called 
<code>title</code> and <code>checked</code>.

There are really just two types of operations you can do in Realm: read and write. 
All these operations need to be done within a context. Even though Realm is built to 
be super fast however you use it, we can still gain a performance boost by reusing 
contexts as much as possible. A good way to reuse contexts is to set them as properties: 
a smart context for reading and a regular context for writing.

@@example setup_contexts @@

Using `RLMContext`, tables can be accessed simultaneously by 
multiple threads, processes, or applications.

Creating a table can be done using a write block on our <code>writeContext</code>:

@@example create_table @@

Calling <code>isEmpty</code> on the <code>RLMTransaction</code> is a good way to 
make sure the table is only created once.

When using smart contexts as is the case here, it's important to observe 
<code>RLMContextDidChangeNotification</code> to know when tables have been updated:

@@example: setup_notifications @@

Adding a row to a table must be done within a write block on a regular context:

@@example: add_row @@

The code above highlights the two main ways to add a new row: using an array and 
using a dictionary. It's important to preserve the order of columns when adding 
a row with an array, but not when adding with a dictionary.

Deleting rows must be done within a write block on a regular context:

@@example delete_row @@

It's also possible to iterate over a table's rows using a <code>for...in</code> loop:

@@example iteration @@

Another powerful way to extract rows from an <code>RLMTable</code> is to filter 
its rows with an <code>NSPredicate</code>:

@@example query @@

** Next steps

<ol>

<li>This was just a brief overview of what's possible with Realm. Feel free to download 
the sample code from this tutorial to play with Realm. It may be helpful to refer to the 
<a href="http://www.tightdb.com/documentation/ObjectiveC_ref/1/Reference/">reference
documentation</a> for more in-depth information about the API.</li>

<li>Feel free to contact <a href="mailto:support@tightdb.com">support</a> 
for help or inspiration to tackling your particular problems - we appreciate 
your feedback, feature requests and challenges!</li>

</ol>
