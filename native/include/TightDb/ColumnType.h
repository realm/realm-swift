#ifndef __TDB_COLUMNTYPE__
#define __TDB_COLUMNTYPE__

#include <cstdlib>

#ifdef __cplusplus
namespace tightdb {
enum ColumnType {
	// Single ref
	COLUMN_TYPE_INT,
	COLUMN_TYPE_BOOL,
	COLUMN_TYPE_STRING,
	COLUMN_TYPE_DATE,
	COLUMN_TYPE_BINARY,
	COLUMN_TYPE_TABLE,
	COLUMN_TYPE_MIXED,

	// Double refs
	COLUMN_TYPE_STRING_ENUM
};

struct BinaryData {
	const void* pointer;
	size_t len;
};

}
#else
#include <stdlib.h>
typedef enum  {
	// Single ref
	COLUMN_TYPE_INT,
	COLUMN_TYPE_BOOL,
	COLUMN_TYPE_STRING,
	COLUMN_TYPE_DATE,
	COLUMN_TYPE_BINARY,
	COLUMN_TYPE_TABLE,
	COLUMN_TYPE_MIXED,
    
	// Double refs
	COLUMN_TYPE_STRING_ENUM
} ColumnType;

typedef struct  {
	const void* pointer;
	size_t len;
} BinaryData;
#endif


#endif //__TDB_COLUMNTYPE__
