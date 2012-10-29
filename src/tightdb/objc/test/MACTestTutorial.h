//
//  MACTestTutorial.h
//  TightDB
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/TightDb.h>

TDB_TABLE_DEF_3(PeopleTable,
            String, Name,
            Int,    Age,
            Bool,   Hired)

TDB_TABLE_DEF_2(PeopleTable2,
            Bool,   Hired,
            Int,    Age)

@interface MACTestTutorial : SenTestCase

@end
