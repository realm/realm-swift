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
extern int TightdbColumnProxyAllocateCount;
extern int TightdbGroupAllocateCount;
extern int TightdbGroupSharedAllocateCount;
extern int TightdbSpecAllocateCount;
extern int TightdbTableAllocateCount;
extern int TightdbBinaryAllocateCount;
extern int TightdbMixedAllocateCount;
#endif


#ifdef TIGHTDB_DEBUG
#define TEST_CHECK_ALLOC  STAssertEquals(TightdbQueryAllocateCount, 0, @"Zero TightdbQuery allocated"); \
STAssertEquals(TightdbViewAllocateCount, 0, @"Zero TightdbView allocated"); \
STAssertEquals(TightdbCursorAllocateCount, 0, @"Zero TightdbCursor allocated"); \
STAssertEquals(TightdbColumnProxyAllocateCount, 0, @"Zero TightdbColumnProxy allocated"); \
STAssertEquals(TightdbGroupAllocateCount, 0, @"Zero TightdbGroup allocated"); \
STAssertEquals(TightdbGroupSharedAllocateCount, 0, @"Zero TightdbGroupShared allocated"); \
STAssertEquals(TightdbSpecAllocateCount, 0, @"Zero TightdbSpec allocated"); \
STAssertEquals(TightdbBinaryAllocateCount, 0, @"Zero TightdbBinary allocated"); \
STAssertEquals(TightdbMixedAllocateCount, 0, @"Zero TightdbMixed allocated"); \
STAssertEquals(TightdbTableAllocateCount, 0, @"Zero TightdbTable allocated");
#else
#define TEST_CHECK_ALLOC
#endif
