//
//  MACTestGroupMisc2.h
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>
#include "TightDb.h"

TDB_TABLE_DEF_4(MyTable,
            String, Name,
            Int,    Age,
            Bool,   Hired,
            Int,	 Spare)

TDB_TABLE_DEF_2(MyTable2,
            Bool,   Hired,
            Int,    Age)

@interface MACTestGroupMisc2 : SenTestCase

@end
