#import <Realm/Realm.h>

@interface StringObject : RLMObject

@property NSString *stringProp;

@end

RLM_ARRAY_TYPE(StringObject);

@interface RubyMotionRealmObject : RLMObject

@property BOOL          boolProp;
@property int           intProp;
@property float         floatProp;
@property double        doubleProp;
@property NSString     *stringProp;
@property NSData       *binaryProp;
@property NSDate       *dateProp;
@property bool          cBoolProp;
@property long          longProp;
@property id            mixedProp;
@property StringObject *objectProp;

// FIXME: Support array properties in RubyMotion
// @property RLMArray<StringObject> *arrayProp;

@end
