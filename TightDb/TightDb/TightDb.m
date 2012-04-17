//
//  TightDb.m
//  TightDb
//
//  Created by Thomas Andersen on 16/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//
#import <Foundation/Foundation.h>
#include "TightDb.h"
TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)

TDB_TABLE_4(MyTable,
String, Name,
Int,    Age,
Bool,   Hired,
Int,	 Spare)

TDB_TABLE_2(MyTable2,
            Bool,   Hired,
            Int,    Age)

#define TIGHT_IMPL
#include "TightDb.h"

TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)

TDB_TABLE_4(MyTable,
            String, Name,
            Int,    Age,
            Bool,   Hired,
            Int,	 Spare)

TDB_TABLE_2(MyTable2,
Bool,   Hired,
Int,    Age)



