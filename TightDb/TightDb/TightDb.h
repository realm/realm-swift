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
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
self = [super init]; \
if (self) { \
if (block) block(self); \
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
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insertDone]; \
} \
-(void)insert:(size_t)ndx col1:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2 \
{ \
    [self insert##CType1:0 ndx:ndx value:CName1]; \
    [self insert##CType2:1 ndx:ndx value:CName2]; \
    [self insertDone]; \
} \
@end 

#undef TDB_TABLE_4
#define TDB_TABLE_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@implementation TableName \
@synthesize CName1 = _##CName1; \
@synthesize CName2 = _##CName2; \
@synthesize CName3 = _##CName3; \
@synthesize CName4 = _##CName4; \
\
-(id)initWithBlock:(TopLevelTableInitBlock)block \
{ \
self = [super init]; \
if (self) { \
if (block) block(self); \
[self registerColumn:COLTYPE##CType1 name:[NSString stringWithUTF8String:#CName1]]; \
[self registerColumn:COLTYPE##CType2 name:[NSString stringWithUTF8String:#CName2]]; \
[self registerColumn:COLTYPE##CType3 name:[NSString stringWithUTF8String:#CName3]]; \
[self registerColumn:COLTYPE##CType4 name:[NSString stringWithUTF8String:#CName4]]; \
\
_##CName1 = [[OCColumnProxy##CType1 alloc] initWithTable:self column:0]; \
_##CName2 = [[OCColumnProxy##CType2 alloc] initWithTable:self column:1]; \
_##CName3 = [[OCColumnProxy##CType3 alloc] initWithTable:self column:2]; \
_##CName4 = [[OCColumnProxy##CType4 alloc] initWithTable:self column:3]; \
} \
return self; \
} \
-(void)add:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2 col3:(tdbOCType##CType3)CName3 col4:(tdbOCType##CType4)CName4 \
{ \
const size_t ndx = [self getSize]; \
[self insert##CType1:0 ndx:ndx value:CName1]; \
[self insert##CType2:1 ndx:ndx value:CName2]; \
[self insert##CType3:2 ndx:ndx value:CName3]; \
[self insert##CType4:3 ndx:ndx value:CName4]; \
[self insertDone]; \
} \
-(void)insert:(size_t)ndx col1:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2 col3:(tdbOCType##CType3)CName3 col4:(tdbOCType##CType4)CName4 \
{ \
[self insert##CType1:0 ndx:ndx value:CName1]; \
[self insert##CType2:1 ndx:ndx value:CName2]; \
[self insert##CType3:2 ndx:ndx value:CName3]; \
[self insert##CType4:3 ndx:ndx value:CName4]; \
[self insertDone]; \
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

#undef TDB_TABLE_4
#define TDB_TABLE_4(TableName, CType1, CName1, CType2, CName2, CType3, CName3, CType4, CName4) \
@interface TableName : OCTopLevelTable \
@property(nonatomic, strong) OCColumnProxy##CType1 *CName1; \
@property(nonatomic, strong) OCColumnProxy##CType2 *CName2; \
@property(nonatomic, strong) OCColumnProxy##CType3 *CName3; \
@property(nonatomic, strong) OCColumnProxy##CType4 *CName4; \
-(void)add:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2 col3:(tdbOCType##CType3)CName3 col4:(tdbOCType##CType4)CName4; \
-(void)insert:(size_t)ndx col1:(tdbOCType##CType1)CName1 col2:(tdbOCType##CType2)CName2 col3:(tdbOCType##CType3)CName3 col4:(tdbOCType##CType4)CName4; \
@end 


#endif

