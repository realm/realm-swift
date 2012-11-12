#import <tightdb/objc/group.h>
#import <tightdb/objc/tightdb.h>

TDB_TABLE_1(TestTable,
            Int, Value)

int main()
{
    @autoreleasepool {
        Group *db = [Group group];
        TestTable *t = (TestTable *)[db getTable:@"test" withClass:[TestTable class]];
        return t ? 0 : 1;
    }
}
