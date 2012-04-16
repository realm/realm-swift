#ifndef __TDB_CTABLE__
#define __TDB_CTABLE__

#ifdef _MSC_VER
#include "win32/stdint.h"
#else
#include <inttypes.h>
#include <stdint.h>
#endif

#include <time.h>

#include "ColumnType.h"
#include <cstdlib> // size_t


#ifdef __cplusplus
extern "C" {
#else
#include <stdbool.h>
#endif

typedef enum ColumnType ColumnType;
typedef struct Table Table;
typedef struct TableView TableView;

	/*** Table ************************************/

	/* Creating and deleting tables */
	Table* table_new();
	void table_delete(Table* t);

	/* Working with columns */
	size_t table_register_column(Table* t, ColumnType type, const char* name);
	size_t table_get_column_count(const Table* t);
	size_t table_get_column_index(const Table* t, const char* name);
	const char* table_get_column_name(const Table* t, size_t ndx);
	ColumnType table_get_column_type(const Table* t, size_t ndx);

	/* Table size */
	bool table_is_empty(const Table* t);
	size_t table_get_size(const Table* t);

	/* Removing rows */
	void table_clear(Table* t);
	void table_delete_row(Table* t, size_t ndx);

	/* Getting values */
	int64_t table_get_int(const Table* t, size_t column_id, size_t ndx);
	bool table_get_bool(const Table* t, size_t column_id, size_t ndx);
	time_t table_get_date(const Table* t, size_t column_id, size_t ndx);
	const char* table_get_string(const Table* t, size_t column_id, size_t ndx);

	/* Setting values */
	void table_set_int(Table* t, size_t column_id, size_t ndx, int64_t value);
	void table_set_bool(Table* t, size_t column_id, size_t ndx, bool value);
	void table_set_date(Table* t, size_t column_id, size_t ndx, time_t value);
	void table_set_string(Table* t, size_t column_id, size_t ndx, const char* value);

	/* Inserting values */
	void table_add(Table* t, ...);
	void table_insert(Table* t, size_t ndx, ...);

	/* NOTE: Low-level insert functions. Always insert in all columns at once
	** and call table_insert_done after to avoid table getting un-balanced. */
	void table_insert_int(Table* t, size_t column_id, size_t ndx, int value);
	void table_insert_int64(Table* t, size_t column_id, size_t ndx, int64_t value);
	void table_insert_bool(Table* t, size_t column_id, size_t ndx, bool value);
	void table_insert_date(Table* t, size_t column_id, size_t ndx, time_t value);
	void table_insert_string(Table* t, size_t column_id, size_t ndx, const char* value);
	void table_insert_done(Table* t);

	/* Indexing */
	bool table_has_index(const Table* t, size_t column_id);
	void table_set_index(Table* t, size_t column_id);

	/* Searching */
	size_t table_find_int(const Table* t, size_t column_id, int value);
	size_t table_find_int64(const Table* t, size_t column_id, int64_t value);
	size_t table_find_bool(const Table* t, size_t column_id, bool value);
	size_t table_find_date(const Table* t, size_t column_id, time_t value);
	size_t table_find_string(const Table* t, size_t column_id, const char* value);

	TableView* table_find_all_int64(Table* t, size_t column_id, int64_t value);
	TableView* table_find_all_hamming(Table* t, size_t column_id, uint64_t value, size_t max);


	/*** TableView ************************************/

	/* Creating and deleting tableviews */
	void tableview_delete(TableView* t);
	
	/* TableView size */
	bool tableview_is_empty(const TableView* t);
	size_t tableview_get_size(const TableView* t);

	/* Getting values */
	int64_t tableview_get_int(const TableView* t, size_t column_id, size_t ndx);
	bool tableview_get_bool(const TableView* t, size_t column_id, size_t ndx);
	time_t tableview_get_date(const TableView* t, size_t column_id, size_t ndx);
	const char* tableview_get_string(const TableView* t, size_t column_id, size_t ndx);

	/* Setting values */
	void tableview_set_int(TableView* t, size_t column_id, size_t ndx, int64_t value);
	void tableview_set_bool(TableView* t, size_t column_id, size_t ndx, bool value);
	void tableview_set_date(TableView* t, size_t column_id, size_t ndx, time_t value);
	void tableview_set_string(TableView* t, size_t column_id, size_t ndx, const char* value);

#ifdef __cplusplus
} //extern "C"
#endif

#endif /*__TDB_CTABLE__*/
