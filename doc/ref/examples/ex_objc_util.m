#import <Realm/Realm.h>

void remove_default_persistence_file()
{
    [[NSFileManager defaultManager] removeItemAtPath:[RLMTransactionManager defaultPath] error:nil];
}
