* TightDB Objective C Interface

This short tutorial to TightDB will introduce you to
commonly used features of TightDB. Please refer to the <a href="http://www.tightdb.com/documentation/1/Reference/">reference documentation</a> for further details.

TightDB is a very fast embedded database that integrates transparently
into Objective C and gives you the full benefits of a database, but
with a much lower memory footprint and higher performance than native
data structures. It is also much more flexible and has an easy to use interface.

TightDB data structures are represented by tables with typed and
untyped columns. A column in a table can be any of the following
column types: Integers, Booleans, Floats, Doubles, Strings, Dates,
Binary, Tables, and Mixed (any of the previous types, i.e. untyped). More datatypes will follow.

The core classes of TightDB are <code>TDBTable</code>,
<code>TDBContext</code>, and <code>TDBTransaction</code>. A table is where
data is stored, while a context can be used to work with
persistent data (memory or disk). Transactions are be read or write
operations within a context.

** Executing the tutorial

While you walk through the below tutorial you may find it beneficial to actually execute the code.
The source code for the tutorial is <a href="http://www.tightdb.com/downloads&/tutorial-ios.zip">avaiable</a>
as a iOS project.

** Creating tables

First, let's create a table with 3 columns using the typed table interface:

@@example create_table @@

The <code>TIGHTDB_TABLE_3</code> is a macro which creates the appropriate Objective C classes
including <code>PeopleTable</code>.

The above code instantiates a TightDB table with 3 typed columns called: <code>Name</code>, <code>Age</code>,
and <code>Hired</code>.

We add rows to the end of the table using the <code>addRow</code>
method. The method <code>addRow</code> allows you to add a row
using object literal either by using an array or dictionary.
The order of the elements in the array must be the same as the order in
which we created the table columns with <code>TDB_TABLE_3()}@@</code>
while order is not important when you add a row using a dictionary.

The below code appends 5 rows to our table:

@@example insert_rows @@

Since tables are ordered, you can also insert rows at specific row positions:

@@example insert_at_index @@

To get the size of our table (number of rows) we can use the
<code>rowCount</code> property.

@@example number_of_rows @@

** Working with individual rows

To access the individual rows of our table, we use brackets
(<code>[]</code>) or the <code>rowAtIndex</code> method. A row is
represented as a special object. In the
general a row an instance of the <code>TDBRow</code> class. In the
case of the typed table, the class is named <code>PeopleTableRow</code>.

@@example accessing_rows @@

To get the last row the <tt>lastRow</tt> method can be used, while
<code>firstRow</code> can be used access the first row.

@@example last_row @@

It is possible update an entire row using object literals:

@@example updating_entire_row @@

Deleting a specific row can be done with the <code>removeRowAtIndex</code>:

@@example deleting_row @@

Using the <code>for ... in</code> construction, you can
easily iterate over all rows in a table:


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

** Simple Searching

To find values in a specific column, you use the <code>find</code> method:

@@example simple_seach @@

** Advanced Queries

More advanced queries can be performed through query objects. Advanced
queries can involve more than one column, and when the query is
defined once, different operations can be performed with it. A query
is instantiated with <code>where</code> method. In the general case, a
query object is an instance of the <code>TDBQuery</code> class but for
the typed table <code>PeopleTable</code> class, the class is named
<code>PeopleTableQuery</code>.

The query class has methods to perform operations relevant for the
particular column type. All comparison operations return the query
object itself, so they can be chained.

You can perform some operations with the query itself, or use
<code>findAll</code> method to get a table view with all the matching rows.

The code below illustrates the simplicity and expressiveness of the
fluent query interface (albeit with a somewhat hypothetical query):

@@example advanced_search @@

Note that the result is a live table view, which allows you to
directly access and modify the values in the original table.

You can do much more advanced queries with parenthesis and <i>or</i>
operators etc. Please see the reference manual for details.

** Transactions

You can create your tables within a context, and use the context to serialize
your data to/from disk or memory buffers. The context is implemented
by the class <code>TDBContext</code>.

The transactional support in TightDB is provided by the
<code>TDBTransaction</code> class. It provides an atomic access to your
data, and transactions are divided into read and write
transactions. If a write transaction succeeds, your data is persistent
to a storage media. Using transactions, tables can be accessed
simultaneously by multiple threads, processes, or applications.

@@example transaction @@


** Next steps

<ol>

<li>You can now play with the basic features of TightDB by changing and executing the tutorial code.
It may be helpful to refer to the <a
href="http://www.tightdb.com/documentation/ObjectiveC_ref/1/Reference/">reference
documentation</a> for details of the full API. </li>

<li>Feel free to contact <a
href="mailto:support@tightdb.com">support</a> for help or inspiration
to cracking your particular problems - we appreciate your feedback and
challenges!</li>

</ol>
