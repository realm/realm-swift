#import <tightdb/objc/group.h>
#import <tightdb/objc/tightdb.h>

TIGHTDB_TABLE_1(TestTable,
                Value, Int)

int main()
{
    @autoreleasepool {
        TightdbGroup *db = [TightdbGroup group];
        TestTable *t = (TestTable *)[db getTable:@"test" withClass:[TestTable class]];
        return t ? 0 : 1;
    }
}
