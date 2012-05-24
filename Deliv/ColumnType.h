#ifndef __TDB_COLUMNTYPE__
#define __TDB_COLUMNTYPE__

#ifdef __cplusplus
#include <cstdlib>
enum ColumnType {
	// Single ref  // Make sure numbers match with tightdb columntype.
	COLUMN_TYPE_INT = 0,
	COLUMN_TYPE_BOOL = 1,
	COLUMN_TYPE_STRING = 2,
	COLUMN_TYPE_DATE = 3,
	COLUMN_TYPE_BINARY = 4,
	COLUMN_TYPE_TABLE = 5,
	COLUMN_TYPE_MIXED = 6,
    
	// Double refs
	COLUMN_TYPE_STRING_ENUM = 7
};
#else
#include <stdlib.h>
typedef enum  {
	// Single ref
	COLUMN_TYPE_INT = 0,
	COLUMN_TYPE_BOOL = 1,
	COLUMN_TYPE_STRING = 2,
	COLUMN_TYPE_DATE = 3,
	COLUMN_TYPE_BINARY = 4,
	COLUMN_TYPE_TABLE = 5,
	COLUMN_TYPE_MIXED = 6,
    
	// Double refs
	COLUMN_TYPE_STRING_ENUM = 7
} ColumnType;
#endif


#endif //__TDB_COLUMNTYPE__