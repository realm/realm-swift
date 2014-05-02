#import <Realm/Realm.h>

@class People;

RLM_DEFINE_TABLE_TYPE_FOR_OBJECT_TYPE(PeopleTable, People)

@interface People : RLMRow

@property NSString *Name;
@property int Age;
@property BOOL Hired;

@end
