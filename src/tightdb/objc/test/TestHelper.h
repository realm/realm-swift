//
//  TestHelper.h
//  TightDbObjcDyn
//
//  Created by Thomas Andersen on 7/1/13.
//  Copyright (c) 2013 Thomas Andersen. All rights reserved.
//

#ifdef TIGHTDB_DEBUG
extern int TightdbQueryAllocateCount;
extern int TightdbViewAllocateCount;
extern int TightdbCursorAllocateCount;
extern int TightdbGroupAllocateCount;
extern int TightdbSpecAllocateCount;
extern int TightdbTableAllocateCount;
#endif


#ifdef TIGHTDB_DEBUG
#define TEST_CHECK_ALLOC  STAssertEquals(0, TightdbQueryAllocateCount, @"Zero TightdbQuery allocated"); \
STAssertEquals(0, TightdbViewAllocateCount, @"Zero TightdbView allocated"); \
STAssertEquals(0, TightdbCursorAllocateCount, @"Zero TightdbCursor allocated"); \
STAssertEquals(0, TightdbGroupAllocateCount, @"Zero TightdbGroup allocated"); \
STAssertEquals(0, TightdbSpecAllocateCount, @"Zero TightdbSpec allocated"); \
STAssertEquals(0, TightdbTableAllocateCount, @"Zero TightdbTable allocated");
#else
#define TEST_CHECK_ALLOC
#endif
