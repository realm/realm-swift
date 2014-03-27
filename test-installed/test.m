#import <tightdb/objc/Tightdb.h>

int main()
{
    @autoreleasepool {
        TDBTable* table = [[TDBTable alloc] init];

        [table addColumnWithName:@"first" andType:TDBIntType];
        [table addColumnWithName:@"second" andType:TDBIntType];

        [table addRow:@[@1, @2]];

        return [table rowCount]>0?0:1;
    }
}
