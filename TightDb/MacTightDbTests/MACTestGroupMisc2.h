//
//  MACTestGroupMisc2.h
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#include "TightDb.h"

TDB_TABLE_4(MyTable,
            String, Name,
            Int,    Age,
            Bool,   Hired,
            Int,	 Spare)

TDB_TABLE_2(MyTable2,
            Bool,   Hired,
            Int,    Age)

@interface MACTestGroupMisc2 : SenTestCase

@end
