////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTable.h"
#import "RLMView.h"
#import "RLMRow.h"



//
// The selectors in this interface are not meant to be used directly.
// However, they are public so that the typed table macros can use them.
//

// private extensions
@interface RLMTable ()
// gets current object class
// sets the current object type for this table and trys to update the table to support objects of type objectClass
@property (nonatomic, assign) Class objectClass;

// the object class returned when accessing rows
@property (nonatomic, readonly) Class proxyObjectClass;

// returns YES if you can currently insert objects of type Class
-(BOOL)canInsertObjectOfClass:(Class)objectClass;

// returns YES if it's possible to update the table to support objects of type Class
-(BOOL)canUpdateToSupportObjectClass:(Class)objectClass;

// index path describing object position in the system (table/row/property, etc)
@property (nonatomic) NSIndexPath *indexPath;

@end

@interface RLMRow()
@property (nonatomic, weak) RLMTable *table;
@property (nonatomic, assign) NSUInteger ndx;
@end

// private category
@interface RLMTable (Private)

-(id)_initRaw;

-(NSUInteger)RLM_addEmptyRow;
-(NSUInteger)RLM_addEmptyRows:(NSUInteger)numberOfRows;

-(BOOL)RLM_insertBool:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(BOOL)value;
-(BOOL)RLM_insertInt:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(int64_t)value;
-(BOOL)RLM_insertFloat:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(float)value;
-(BOOL)RLM_insertDouble:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(double)value;
-(BOOL)RLM_insertString:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSString *)value;
-(BOOL)RLM_insertBinary:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSData *)value;
-(BOOL)RLM_insertBinary:(NSUInteger)colIndex ndx:(NSUInteger)ndx data:(const char *)data size:(size_t)size;
-(BOOL)RLM_insertDate:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(NSDate *)value;
-(BOOL)RLM_insertSubtable:(NSUInteger)colIndex ndx:(NSUInteger)ndx;
-(BOOL)RLM_insertSubtable:(NSUInteger)colIndex ndx:(NSUInteger)ndx error:(NSError *__autoreleasing *)error;
-(BOOL)RLM_insertMixed:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(id)value;
-(BOOL)RLM_insertMixed:(NSUInteger)colIndex ndx:(NSUInteger)ndx value:(id)value error:(NSError *__autoreleasing *)error;
-(BOOL)RLM_insertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowNdx subtable:(RLMTable *)subtable;
-(BOOL)RLM_insertSubtableCopy:(NSUInteger)colIndex row:(NSUInteger)rowIndex subtable:(RLMTable *)subtable error:(NSError *__autoreleasing *)error;
-(BOOL)RLM_insertDone;

-(BOOL)RLM_boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(int64_t)RLM_intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(float)RLM_floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(double)RLM_doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSDate *)RLM_dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSString *)RLM_stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSData *)RLM_binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(RLMTable *)RLM_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(id)RLM_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass;
-(id)RLM_mixedInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;


-(void)RLM_setInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(void)RLM_setBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)RLM_setFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)RLM_setDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)RLM_setDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)RLM_setString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)RLM_setBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)RLM_setTable:(RLMTable *)aTable inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;
-(void)RLM_setMixed:(id)aMixed inColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)atRowIndex;

-(NSUInteger)RLM_lookup:(NSString *)key;

@end

//
// The selectors in this interface are not meant to be used directly.
// However, they are public so that the typed table macros can use them.
//
@interface RLMView (Private)
-(id)_initWithQuery:(RLMQuery *)query;

-(BOOL)RLM_boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(int64_t)RLM_intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(float)RLM_floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(double)RLM_doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSDate *)RLM_dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
-(NSString *)RLM_stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(TDBBinary *)RLM_binaryInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(RLMTable *)TD_BtableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
//-(id)RLM_tableInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex asTableClass:(Class)tableClass;
-(id)RLM_mixedInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex;
@end

//
// The selectors in this interface are not meant to be used directly.
// However, they are public so that the typed table macros can use them.
//
@interface RLMRow (Private)
-(id)initWithTable:(RLMTable *)table ndx:(NSUInteger)ndx;
-(void)RLM_setNdx:(NSUInteger)ndx;
-(NSUInteger)RLM_index;
@end

