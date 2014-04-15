* TightDB Objective C Interface

This short tutorial to TightDB will introduce you to
commonly used features of TightDB. Please refer to the
<a href="http://www.tightdb.com/documentation/1/Reference/">reference documentation</a>
for further details.

TightDB is a fast embedded database that integrates transparently
into Objective C. It gives you the full benefits of a database, but
with a much lower memory footprint and higher performance than native
data structures.

TightDB data structures are represented by tables with typed and
untyped columns. A column in a table can be of any of the following
column types: Integers, Booleans, Floats, Doubles, Strings, Dates,
Binary blobs, and Tables. Moreover, columns in a table can be of the
type Mixed which means that the values can be of any support type.

The core classes of TightDB are <code>TDBTable</code>,
<code>TDBContext</code>, and <code>TDBTransaction</code>. Tables are where
data is stored, while contexts can be used to work with
persistent data (on disk). Tables within a context can only the access in
a transactional manner, and TightDB distinguish between read and write access.

** Executing the tutorial

While you walk through the tutorial below you may find it beneficial to actually execute the code.
The source code for the tutorial is <a href="http://www.tightdb.com/downloads&/tutorial-ios.zip">available</a>
as an iOS project.

** Creating tables

First, let's create a table with 3 columns using the typed table interface:

@@example create_table @@

The <code>TIGHTDB_TABLE_3</code> is a macro which creates the appropriate Objective C classes
including <code>PeopleTable</code>.

The above code instantiates a TightDB table with 3 typed columns called: <code>Name</code>, <code>Age</code>,
and <code>Hired</code>.

We add rows to the end of the table using the method <code>addRow</code>.
The method <code>addRow</code> allows you to add a row
using object literals either by using an array or a dictionary.
The order of the elements in the array must be the same as the order in
which we created the table columns with <code>TIGHTDB_TABLE_3()</code>
while order is not important when you add a row using a dictionary.

The code below appends 5 rows to our table:

@@example insert_rows @@

Since tables are ordered, you can also insert rows at specific row positions:

@@example insert_at_index @@

To get the number of row in of your table (number of rows) you can use the
<code>rowCount</code> property.

@@example number_of_rows @@

** Working with individual rows

To access the individual rows of our table, we use square brackets
(<code>[]</code>) or the <code>rowAtIndex</code> method. In general a row is
represented as a special object. In the
general a row an instance of the <code>TDBRow</code> class. In the
case of the typed table, the class is named <code>PeopleTableRow</code>.

@@example accessing_rows @@

You can easily access the first and last row like this:

@@example last_row @@

It is possible update an entire row using object literals:

@@example updating_entire_row @@

Deleting a specific row can be done with <code>removeRowAtIndex</code>:

@@example deleting_row @@

Using the <code>for ... in</code> construct, you can
easily iterate over every row in a table:


@@example iteration @@

Which will output the following:

<div class="code">
<pre>
John is 20 years old.
Mary is 21 years old.
Lars is 32 years old.
Eric is 50 years old.
Anni is 43 years old.
</pre>
</div>

** Queries

Queries can be performed through query objects. Advanced
queries can involve more than one column and when the query is
defined once different operations can be performed with it. A query
is instantiated with the <code>where</code> method. In the general case, a
query object is an instance of the <code>TDBQuery</code> class but for
the typed table <code>PeopleTable</code> class, the class is named
<code>PeopleTableQuery</code>.

The query class has methods to perform operations relevant for the
particular column type. All comparison operations return the query
object itself, so they can be chained.

You can perform some operations with the query itself, or use the
<code>findAll</code> method to get a view of all matching rows.

The code below illustrates the simplicity and expressiveness of the
query interface (albeit with a somewhat hypothetical query):

@@example advanced_search @@

Note that the result is a live table view, which allows you to
directly access and modify the values in the original table.

You can do much more advanced queries with parenthesis and <i>or</i>
operators etc. Please see the reference manual for details.

** Transactions

You can create your tables within a context, and use such a context to serialize
your data to/from disk. The context is implemented
by the class <code>TDBContext</code>.

The transactional support in TightDB is provided by the
<code>TDBTransaction</code> class. It provides an atomic access to your
data, and transactions are divided into read and write
transactions. If a write transaction succeeds, your data is persistent
to your device. Using transactions, tables can be accessed
simultaneously by multiple threads, processes, or applications.

@@example transaction @@


** Next steps

<ol>

<li>You can now play with the basic features of TightDB by changing and executing the tutorial code.
It may be helpful to refer to the <a
href="http://www.tightdb.com/documentation/ObjectiveC_ref/1/Reference/">reference
documentation</a> for all the details of the API. </li>

<li>Feel free to contact <a
href="mailto:support@tightdb.com">support</a> for help or inspiration
to cracking your particular problems - we appreciate your feedback and
challenges!</li>

</ol>
