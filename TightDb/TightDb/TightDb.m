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

#define TIGHT_IMPL
#include "TightDb.h"

TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)



