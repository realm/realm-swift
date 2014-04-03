Template
=============================================================
x.x.x Release notes (yyyy—MM-dd)

Objective-C
-----------
The Objective-C API has been updated and your code will break!

### Bugfixes:

* None.

### API breaking changes:

* `???`

### Enhancements:

* `???`

-------------

### Internals:

* `???`


=============================================================
0.6.0 Release notes (yyyy—MM-dd)
Objective-C
-----------
Description......

### Bugfixes:

* none.

### API breaking changes:

* none.

### Enhancements:
* `renameColumnWithIndex:to:` has been added to `TDBTable`.
* `viewWithDistinctValuesInColumnWithIndex` has been added to `TDBTable`.
* Column names can begin with non-capital letters too. The generated `addX`
  selector can look odd. For example, a table with one column with name `age`,
  appending a new row will look like `[table addage:7]`.
* Mixed typed values are better validated when rows are added, inserted, 
  or modified as object literals.


=============================================================
0.5.0 Release notes (2014-04-02)
Objective-C
-----------
The Objective-C API has been updated and your code will break!
Of notable changes a fast interface has been added. 
This interface includes specific methods to get and set values into Tightdb.
To use these methods import <Tightdb/TightdbFast.h>.

### Bugfixes:

* Fixed bug in 64 bit iOS when inserting BOOL as NSNumber.

### API breaking changes:

* `getTableWithName:` renamed to `tableWithName:` in `TDBTransaction`.
* `addColumnWithName:andType:` renamed to `addColumnWithName:type:` in `TDBTable`.
* `columnTypeOfColumn:` renamed to `columnTypeOfColumnWithIndex` in `TDBTable`.
* `columnNameOfColumn:` renamed to `nameOfColumnWithIndex:` in `TDBTable`.
* `addColumnWithName:andType:` renamed to `addColumnWithName:type:` in `TDBDescriptor`.
* Fast getters and setters moved from `TDBRow.h` to `TDBRowFast.h`.

### Enhancements:

### Enhancements:
* Added `minDateInColumnWithIndex` and `maxDateInColumnWithIndex` to `TDBQuery`.
* Transactions can now be started directly on named tables.
* You can create dynamic tables with initial schema.
* `TDBTable` and `TDBView` now have a shared protocol so they can easier be used interchangeably.


=============================================================
0.4.0 Release notes (2014-03-26)

2014-03-26
==========
+ Experimental support for pinning transactions on Context.
+ TDBView now has support for object subscripting.

2014-03-25
==========
! BREAKING CHANGE: TDBMixed removed. Use id and NSObject instead.
! BREAKING CHANGE: insertEmptyRow has been removed from table. Use insertRow:nil atIndex:index instead.

2014-03-24
==========
! BREAKING CHANGE: set*:inColumnWithIndex:atRowIndex: methods have been prefixed with TDB
! BREAKING CHANGE: *:inColumnWithIndex:atRowIndex: methods have been prefixed with TDB
! BREAKING CHANGE: addEmptyRow on table has been removed. Use [table addRow:nil] instead.

2014-03-21
==========
! BREAKING CHANGE: Table findFirstRow and min/max/sum/avg operations has been hidden.
! BREAKING CHANGE: Table.appendRow has been renamed to addRow.
! BREAKING CHANGE: getOrCreateTable on Transaction has been removed.
+ createTable method added on Transaction. Throws exception if table with same name already exists.
! BREAKING CHANGE: Underscore (_) removed from generated typed table classes.
! BREAKING CHANCE: TDBBinary has been removed; use NSData instead.
! BREAKING CHANGE: Underscope (_) removed from generated typed table classes.
! BREAKING CHANCE: Constructor for TDBContext has been renamed to contextWithPersistenceToFile:

2014-03-20
==========
* [TDBQuery parent] and [TDBQuery subtable:] selectors now return self.
! BREAKING CHANCE: Header files are renamed so names match class names.

2014-03-18
==========
! BREAKING CHANGE: Typed interface Cursor has now been renamed to Row.
! BREAKING CHANGE: TDBGroup has been renamed to TDBTransaction.
+ getTableWithName selector added on group.
* getting and creating table methods on group no longer take error argument.

2014-03-17
==========
+ Added firstRow, lastRow selectors on view.
* firstRow and lastRow on table now return nil if table is empty.

2014-03-14
==========
! BREAKING CHANGE: Prepend TDB-prefix on all classes and types.

2014-03-13
==========
+ Adding setObject to TightdbTable (t[2] = @[@1, @"Hello"] is possible).

2014-03-12
==========
+ Adding insertRow to TightdbTable.

2014-03-11
==========
* Extending appendRow to accept NSDictionary.
! BREAKING CHANGE: Most selectors have been renamed in the binding!

2014-03-10
==========
* Return types and parameters changed from size_t to NSUInteger.

2014-03-07
==========
* Adding appendRow to TightdbTable.
* Adding object subscripting.
* Adding method removeColumn on table.

2014-03-05
==========
+ tableview now supports sort on column with column type bool, date and int
+ tableview has method for checking the column type of a specified column
+ tableview has method for getting the number of columns
* Adding methods getVersion, getCoreVersion and isAtLeast.

2014-02-27
==========
* Adding a simple class for version numbering.
* Adding get-version and set-version targets to build.sh.
! BREAKING CHANGE: addRow renamed to addEmptyRow

2013-11-08
==========
* Adding support for one-line installer (suppressing output and don't die too hard).
