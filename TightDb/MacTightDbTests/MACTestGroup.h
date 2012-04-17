//
//  MACTestGroup.h
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#include "TightDb.h"

TDB_TABLE_2(TestTableGroup,
			String,     First,
			Int,        Second)

@interface MACTestGroup : SenTestCase

@end
