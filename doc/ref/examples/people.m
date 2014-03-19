#import <Tightdb/Tightdb.h>
#import "people.h"

TIGHTDB_TABLE_IMPL_3(PeopleTable,
                     Name, String,
                     Age,  Int,
                     Hired, Bool)