Signature Specification
=======================

This document contains a review of the current implementation and proposes changes. In general the current implemenation is to the left and the proposal is to the right, except if there is no current implementation, then only the proposal is written (and to the left).

Typed Table
-----------
    -(BOOL)add##CName1:(TIGHTDB_ARG_TYPE(CType1))CName1; \								(jjepsen: delete, see memo1)
    -(BOOL)add##CName1:(TIGHTDB_ARG_TYPE(CType1))CName1 error:(NSError **)error; \		(jjepsen: delete, see memo1)
    -(void)insertAtIndex:(size_t)ndx CName1:(TIGHTDB_ARG_TYPE(CType1))CName1; \			(jjepsen: delete for consistency reasons, or keep)
    -(TableName##_Query *)where; \														
    -(TableName##_Cursor *)add; \														(jjepsen: addRow, to override dynamic one)
    -(TableName##_Cursor *)objectAtIndex:(size_t)ndx; \									(jjepsen: curserAtIndex:)
    -(TableName##_Cursor *)lastObject; \												(jjepsen: curserAtLastIndex)

Insert row is missing:

	-(TableName##_Curser *)insertRowAtIndex:

Dynamic Table
-------------

For some reason the type is omitted for ints:

    -(int64_t)get:(size_t)colNdx ndx:(size_t)ndx;										(jjepsen: getIntInColumn:AtRow:)
    -(BOOL)set:(size_t)colNdx ndx:(size_t)ndx value:(int64_t)value;						(jjepsen: setInt:InColumn:AtRow:)

Add row should return a curser instead of an index for consistency with the typed API. The curser class is not yet implmented.

	-(size_t)addRow;																	(jjepsen: (TightdbCurser*)addRow)
    -(BOOL)remove:(size_t)ndx;															(jjepsen: removeRowAtIndex:)
    
Insert row is missing
	
	-(TightdbCurser *)insertRowAtIndex:

	-(int64_t)sumInt:(size_t)colNdx;													(jjepsen: sumIntInColumn:)