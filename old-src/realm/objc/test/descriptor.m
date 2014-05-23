#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>
#import <realm/objc/RLMPrivate.h>

@interface RLMTestDescriptor : RLMTestCase

@end

@implementation RLMTestDescriptor

- (void)testDescriptor
{
    RLMRealm *realm = [self realmWithTestPath];
    [realm beginWriteTransaction];
    RLMTable *table = [realm createTableWithName:@"table" columns:@[@"subtable", @[]]];
    [table addRow:nil];
    RLMTable *subtable = table.lastRow[@"subtable"];
    RLMDescriptor *desc = subtable.descriptor;
    [desc addColumnWithName:@"Foo" type:RLMTypeInt];
}

@end
