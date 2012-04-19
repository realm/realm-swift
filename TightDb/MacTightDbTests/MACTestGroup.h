//
//  MACTestGroup.h
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>
#include "TightDb.h"

TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)


@interface MACTestGroup : SenTestCase

@end
