#ifndef __TDB_COLUMNTYPE__
#define __TDB_COLUMNTYPE__

// Make sure numbers match with <tightdb/column_type.hpp>

#ifdef __cplusplus
#include <cstdlib>
enum ColumnType {
	COLUMN_TYPE_INT         =  0,
	COLUMN_TYPE_BOOL        =  1,
	COLUMN_TYPE_STRING      =  2,
	COLUMN_TYPE_STRING_ENUM =  3, // double refs
	COLUMN_TYPE_BINARY      =  4,
	COLUMN_TYPE_TABLE       =  5,
	COLUMN_TYPE_MIXED       =  6,
	COLUMN_TYPE_DATE        =  7,
        COLUMN_TYPE_RESERVED1   =  8, // DateTime
        COLUMN_TYPE_RESERVED2   =  9, // Float
        COLUMN_TYPE_RESERVED3   = 10, // Double
        COLUMN_TYPE_RESERVED4   = 11  // Decimal

	// Double refs
};
#else
#include <stdlib.h>
typedef enum  {
	COLUMN_TYPE_INT         =  0,
	COLUMN_TYPE_BOOL        =  1,
	COLUMN_TYPE_STRING      =  2,
	COLUMN_TYPE_STRING_ENUM =  3, // double refs
	COLUMN_TYPE_BINARY      =  4,
	COLUMN_TYPE_TABLE       =  5,
	COLUMN_TYPE_MIXED       =  6,
	COLUMN_TYPE_DATE        =  7,
        COLUMN_TYPE_RESERVED1   =  8, // DateTime
        COLUMN_TYPE_RESERVED2   =  9, // Float
        COLUMN_TYPE_RESERVED3   = 10, // Double
        COLUMN_TYPE_RESERVED4   = 11  // Decimal
} ColumnType;
#endif


#endif //__TDB_COLUMNTYPE__
