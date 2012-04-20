//
//  TightDb.m
//  TightDB
//

#import <Foundation/Foundation.h>
#include "TightDb.h"
TDB_TABLE_DEF_2(TestTableGroup,
			String,     First,
			Int,        Second)

TDB_TABLE_DEF_4(MyTable,
String, Name,
Int,    Age,
Bool,   Hired,
Int,	 Spare)

TDB_TABLE_DEF_2(MyTable2,
            Bool,   Hired,
            Int,    Age)

TDB_TABLE_IMPL_2(TestTableGroup,
			String,     First,
			Int,        Second)

TDB_TABLE_IMPL_4(MyTable,
            String, Name,
            Int,    Age,
            Bool,   Hired,
            Int,	 Spare)

TDB_TABLE_IMPL_2(MyTable2,
Bool,   Hired,
Int,    Age)





