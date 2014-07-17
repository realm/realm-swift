#import <Realm/Realm.h>

@interface StringObject : RLMObject

@property NSString *stringCol;

@end

RLM_ARRAY_TYPE(StringObject);

@interface RubyMotionRealmObject : RLMObject

@property BOOL          boolCol;
@property int           intCol;
@property float         floatCol;
@property double        doubleCol;
@property NSString     *stringCol;
@property NSData       *binaryCol;
@property NSDate       *dateCol;
@property bool          cBoolCol;
@property long          longCol;
@property id            mixedCol;
@property StringObject *objectCol;

// FIXME: Support array properties in RubyMotion
// @property RLMArray<StringObject> *arrayCol;

@end
