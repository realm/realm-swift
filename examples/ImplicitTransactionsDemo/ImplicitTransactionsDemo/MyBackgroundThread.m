#import <Tightdb/Tightdb.h>

#import "MyBackgroundThread.h"


@implementation MyBackgroundThread

- (void)main
{
    TDBContext *context =
        [TDBContext contextPersistedAtPath:[self pathForName:@"demo.tightdb"] error:nil];

    __block int i = 0;
    for (;;) {
        [NSThread sleepForTimeInterval:5.0];
        [context writeUsingBlock:^(TDBTransaction *transact) {
            TDBTable *table = [transact tableWithName:@"demo"];
            ++i;
            [table firstRow][0] = [NSString stringWithFormat:@"First %i", i];
            table[[table rowCount]/2][0] = [NSString stringWithFormat:@"Middle %i", i];
            [table lastRow][0] = [NSString stringWithFormat:@"Last %i", i];
            return YES; // Commit
        } error:nil];
    }
}

- (NSString *)pathForName:(NSString *)name
{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%@", [dirs objectAtIndex:0], name];
}

@end
