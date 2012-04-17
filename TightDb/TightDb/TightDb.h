//
//  TightDb.h
//  TightDb
//
//  Created by Thomas Andersen on 16/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "OCTable.h"

#ifdef TIGHT_IMPL
#undef TDB_TABLE_2
#define TDB_TABLE_2(TableName, CType1, CName1, CType2, CName2) \
@implementation TableName \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
\
-(id)init \
{ \
self = [super init]; \
if (self) { \
[self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
[self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
\
_##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
_##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
} \
return self; \
} \
-(void)add:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2 \
{ \
    const size_t ndx = [self getSize]; \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType1:1 ndx:ndx value:CName1]; \
} \
-(void)insert:(size_t)ndx col1:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType1:1 ndx:ndx value:CName1]; \
} \
@end 
#else
#undef TDB_TABLE_2
#define TDB_TABLE_2(TableName, CType1, CName1, CType2, CName2) \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
-(void)add:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2; \
-(void)insert:(size_t)ndx col1:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2; \
@end 
#endif

