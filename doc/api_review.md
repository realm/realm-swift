Signature Specification
=======================

This document contains a review of the current implementation and proposes changes. In general the current implementation is to the left and the proposal is to the right, except if there is no current implementation, then only the proposal is written (and to the left).

Typed Table
-----------
    -(BOOL)add##CName1:(TIGHTDB_ARG_TYPE(CType1))CName1;                           (delete, see memo1)
    -(BOOL)add##CName1:(TIGHTDB_ARG_TYPE(CType1))CName1 error:(NSError **)error;   (delete, see memo1)
    -(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_ARG_TYPE(CType1))CName1;      (delete for consistency reasons, or keep)
    -(TableName##_Query *)where;														
    -(TableName##_Cursor *)add;                                                    (addRow, to override dynamic one)
    -(TableName##_Cursor *)objectAtIndex:(size_t)ndx;                              (curserAtIndex:)
    -(TableName##_Cursor *)lastObject;                                             (curserAtLastIndex)

Insert row is missing:

    -(TableName##_Curser *)insertRowAtIndex:

Dynamic Table
-------------

For some reason the type is omitted for ints:

    -(int64_t)get:(size_t)colNdx ndx:(size_t)ndx;                                  (getIntInColumn:AtRow:)
    -(BOOL)set:(size_t)colNdx ndx:(size_t)ndx value:(int64_t)value;                (setInt:InColumn:(size_t)ColNdx AtRow:

Columns are referred to by index right now, Alexander suggested names (NSString), which would require maintaining of a lookup table for getting the index indirectly. This could be considered for all dynamic API methods referring to columns.

    -(BOOL)set:(size_t)colNdx ndx:(size_t)ndx value:(int64_t)value;                (setInt:InColumn:(NSString*)ColNdx AtRow:

Add row should return a curser instead of an index for consistency with the typed API. The curser class is not yet implmented.

    -(size_t)addRow;                                                               ((TightdbCurser*)addRow)
    -(BOOL)remove:(size_t)ndx;                                                     (removeRowAtIndex:)
    
Insert row is missing (edit: appears to be added in ErrorBranch, returning BOOL).
	
    -(TightdbCurser *)insertRowAtIndex:    
    -(int64_t)sumInt:(size_t)colNdx;                                               (sumIntInColumn:)

Typed Query
-----------

The implemention of the query accessors to be changed according to memo1, to support dot notation only.


Naming of condutions could be improved:

-(table##_Query *)equal:(int64_t)value;                                            (isEqualTo:)



Dymanic Query
-------------

Naming of actions could be improved as below:

(NSNumber *)sumFloat:(size_t)colNdx;                                               (sumInFloatColumn:(size_t)colNdx)

Naming of conditions could be improved as below:

-(TightdbQuery *)equalBool:(bool)value colNdx:(size_t)colNdx;                      (column:isEqualToBool:)


The "with" comment (from Alexander)
-----------------------------------

Suggested (here, concrete syntax):

[table addColumnWithType:tightdb_String andName:@"Name"];

Comment from Alenader was that signatures with "With" should occur only when there are corrosponding method(s) without "With", and since we have no addColumn method without arguments, we don't comply with that suggested rule: 

There are many examples in Apples API where the rule does not apply, for instance in NSArray:

firstObjectCommonWithArray:

I propose we allow this notation?
