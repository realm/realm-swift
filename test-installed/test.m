#import <tightdb/objc/Group.h>
#import <tightdb/objc/TightDb.h>

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
