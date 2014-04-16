/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import "RLMTable.h"
#import "RLMView.h"
#import "TDBContext.h"
#import "RLMRow.h"


/**
 * The selectors in this interface is not meant to be used directly.
 * However, they are public so that the typed table macros can use them.
 */
@interface RLMTable (Private)

-(id)_initRaw;

-(NSUInteger)TDB_addEmptyRow;
-(NSUInteger)TDB_addEmptyRows:(NSUInteger)numberOfRows;

-(BOOL)TDB_insertBool:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(BOOL)value;
-(BOOL)TDB_insertInt:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(int64_t)value;
-(BOOL)TDB_insertFloat:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(float)value;
-(BOOL)TDB_insertDouble:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(double)value;
-(BOOL)TDB_insertString:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSString *)value;
-(BOOL)TDB_insertBinary:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSData *)value;
-(BOOL)TDB_insertBinary:(NSUInteger)colIndex ndx:(NSUInteger)ndx data:(const char *)data size:(size_t)size;
-(BOOL)TDB_insertDate:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSDate *)value;
-(BOOL)TDB_insertSubtable:(NSUInteger)colIndex ndx:(NSUInteger)ndx;
-(BOOL)TDB_insertSubtable:(NSUInteger)colIndex ndx:(NSUInteger)ndx error:(NSError *__autoreleasing *)error;
-(BOOL)TDB_insertMixed:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(id)value;
-(BOOL)TDB_insertMixed:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(id)value error:(NSError *__autoreleasing *)error;
-(BOOL)TDB_insertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowNdx subtable:(RLMTable *)subtable;
-(BOOL)TDB_insertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowIndex subtable:(RLMTable *)subtable error:(NSError *__autoreleasing *)error;
-(BOOL)TDB_insertDone;

-(BOOL)TDB_boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(int64_t)TDB_intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(float)TDB_floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(double)TDB_doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSDate *)TDB_dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSString *)TDB_stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSData *)TDB_binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(RLMTable *)TDB_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(id)TDB_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass;
-(id)TDB_mixedInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;


-(void)TDB_setInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(void)TDB_setBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDB_setFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDB_setDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDB_setDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDB_setString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDB_setBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDB_setTable:(RLMTable *)aTable inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)TDB_setMixed:(id)aMixed inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;

@end

/**
 * The selectors in this interface is not meant to be used directly.
 * However, they are public so that the typed table macros can use them.
 */
@interface RLMView (Private)
-(id)_initWithQuery:(RLMQuery *)query;

-(BOOL)TDB_boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(int64_t)TDB_intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(float)TDB_floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(double)TDB_doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSDate *)TDB_dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSString *)TDB_stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(TDBBinary *)TDB_binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(RLMTable *)TD_BtableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(id)TDB_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass;
-(id)TDB_mixedInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
@end

/**
 * The selectors in this interface is not meant to be used directly.
 * However, they are public so that the typed table macros can use them.
 */
@interface RLMRow (Private)
-(id)initWithTable:(RLMTable *)table ndx:(NSUInteger)ndx;
-(void)TDB_setNdx:(NSUInteger)ndx;
-(NSUInteger)TDB_index;
@end

/**
 * The selectors in this interface is not meant to be used directly.
 * However, they are publicly available so that the typed table macros can use them.
 */
@interface TDBContext (Experiment)

/******** Experimental features **********/
-(BOOL)pinReadTransactions;
-(void)unpinReadTransactions;

@end
