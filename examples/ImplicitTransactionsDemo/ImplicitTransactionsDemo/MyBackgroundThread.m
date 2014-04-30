#import <Realm/Realm.h>

#import "MyBackgroundThread.h"


@implementation MyBackgroundThread

- (void)main
{
    RLMTransactionManager *manager = [RLMTransactionManager managerForRealmWithPath:[self pathForName:@"demo.realm"]
                                                                      error:nil];

    __block int i = 0;
    for (;;) {
        [NSThread sleepForTimeInterval:5.0];
        [manager writeUsingBlock:^(RLMRealm *realm) {
            RLMTable *table = [realm tableWithName:@"demo"];
            ++i;
            [table firstRow][0] = [NSString stringWithFormat:@"First %i", i];
            table[[table rowCount]/2][0] = [NSString stringWithFormat:@"Middle %i", i];
            [table lastRow][0] = [NSString stringWithFormat:@"Last %i", i];
        }];
    }
}

- (NSString *)pathForName:(NSString *)name
{
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%@", [dirs objectAtIndex:0], name];
}

@end
