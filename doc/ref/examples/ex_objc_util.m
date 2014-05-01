#import <Realm/Realm.h>

void remove_default_persistence_file()
{
    [[NSFileManager defaultManager] removeItemAtPath:[RLMContext defaultPath] error:nil];
}
