#import <Realm/Realm.h>
#import "people.h"

REALM_TABLE_IMPL_3(People,
                   Name, String,
                   Age,  Int,
                   Hired, Bool)
