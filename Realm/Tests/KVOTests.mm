////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"

#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"

#import <atomic>
#import <memory>
#import <objc/runtime.h>
#import <vector>

RLM_COLLECTION_TYPE(KVOObject)
RLM_COLLECTION_TYPE(KVOLinkObject1)

@interface KVOObject : RLMObject
@property int pk; // Primary key for isEqual:
@property int ignored;

@property BOOL                 boolCol;
@property int16_t              int16Col;
@property int32_t              int32Col;
@property int64_t              int64Col;
@property float                floatCol;
@property double               doubleCol;
@property bool                 cBoolCol;
@property NSString            *stringCol;
@property NSData              *binaryCol;
@property NSDate              *dateCol;
@property RLMObjectId         *objectIdCol;
@property RLMDecimal128       *decimal128Col;
@property NSUUID              *uuidCol;
@property id<RLMValue>         anyCol;

@property KVOObject           *objectCol;

@property RLMArray<RLMBool>       *boolArray;
@property RLMArray<RLMInt>        *intArray;
@property RLMArray<RLMFloat>      *floatArray;
@property RLMArray<RLMDouble>     *doubleArray;
@property RLMArray<RLMString>     *stringArray;
@property RLMArray<RLMData>       *dataArray;
@property RLMArray<RLMDate>       *dateArray;
@property RLMArray<RLMObjectId>   *objectIdArray;
@property RLMArray<RLMDecimal128> *decimal128Array;
@property RLMArray<RLMUUID>       *uuidArray;
@property RLMArray<RLMValue>      *anyArray;
@property RLMArray<KVOObject>     *objectArray;

@property RLMSet<RLMBool>       *boolSet;
@property RLMSet<RLMInt>        *intSet;
@property RLMSet<RLMFloat>      *floatSet;
@property RLMSet<RLMDouble>     *doubleSet;
@property RLMSet<RLMString>     *stringSet;
@property RLMSet<RLMData>       *dataSet;
@property RLMSet<RLMDate>       *dateSet;
@property RLMSet<RLMObjectId>   *objectIdSet;
@property RLMSet<RLMDecimal128> *decimal128Set;
@property RLMSet<RLMUUID>       *uuidSet;
@property RLMSet<RLMValue>      *anySet;
@property RLMSet<KVOObject>     *objectSet;

@property RLMDictionary<NSString *, NSNumber *><RLMString, RLMBool>       *boolDictionary;
@property RLMDictionary<NSString *, NSNumber *><RLMString, RLMInt>        *intDictionary;
@property RLMDictionary<NSString *, NSNumber *><RLMString, RLMFloat>      *floatDictionary;
@property RLMDictionary<NSString *, NSNumber *><RLMString, RLMDouble>     *doubleDictionary;
@property RLMDictionary<NSString *, NSString *><RLMString, RLMString>     *stringDictionary;
@property RLMDictionary<NSString *, NSData *><RLMString, RLMData>         *dataDictionary;
@property RLMDictionary<NSString *, NSDate *><RLMString, RLMDate>         *dateDictionary;
@property RLMDictionary<NSString *, RLMObjectId *><RLMString, RLMObjectId>     *objectIdDictionary;
@property RLMDictionary<NSString *, RLMDecimal128 *><RLMString, RLMDecimal128> *decimal128Dictionary;
@property RLMDictionary<NSString *, NSUUID *><RLMString, RLMUUID>         *uuidDictionary;
@property RLMDictionary<NSString *, NSObject *><RLMString, RLMValue>      *anyDictionary;
@property RLMDictionary<NSString *, KVOObject *><RLMString, KVOObject>    *objectDictionary;

@property NSNumber<RLMInt>    *optIntCol;
@property NSNumber<RLMFloat>  *optFloatCol;
@property NSNumber<RLMDouble> *optDoubleCol;
@property NSNumber<RLMBool>   *optBoolCol;
@end
@implementation KVOObject
+ (NSString *)primaryKey {
    return @"pk";
}
+ (NSArray *)ignoredProperties {
    return @[@"ignored"];
}
@end

@interface KVOLinkObject1 : RLMObject
@property int pk; // Primary key for isEqual:
@property KVOObject *obj;
@property RLMArray<KVOObject> *array;
@property RLMSet<KVOObject> *set;
@end
@implementation KVOLinkObject1
+ (NSString *)primaryKey {
    return @"pk";
}
@end

@interface KVOLinkObject2 : RLMObject
@property int pk; // Primary key for isEqual:
@property KVOLinkObject1 *obj;
@property RLMArray<KVOLinkObject1> *array;
@property RLMSet<KVOLinkObject1> *set;
@property RLMDictionary<NSString *, KVOLinkObject1 *><RLMString, KVOLinkObject1> *dictionary;
@end
@implementation KVOLinkObject2
+ (NSString *)primaryKey {
    return @"pk";
}
@end

@interface PlainKVOObject : NSObject
@property int ignored;

@property BOOL            boolCol;
@property int16_t         int16Col;
@property int32_t         int32Col;
@property int64_t         int64Col;
@property float           floatCol;
@property double          doubleCol;
@property bool            cBoolCol;
@property NSString       *stringCol;
@property NSData         *binaryCol;
@property NSDate         *dateCol;
@property PlainKVOObject *objectCol;
@property RLMObjectId    *objectIdCol;
@property RLMDecimal128  *decimal128Col;
@property NSUUID         *uuidCol;
@property id<RLMValue>    anyCol;

@property NSMutableArray *boolArray;
@property NSMutableArray *intArray;
@property NSMutableArray *floatArray;
@property NSMutableArray *doubleArray;
@property NSMutableArray *stringArray;
@property NSMutableArray *dataArray;
@property NSMutableArray *dateArray;
@property NSMutableArray *objectArray;
@property NSMutableArray *objectIdArray;
@property NSMutableArray *decimal128Array;
@property NSMutableArray *uuidArray;
@property NSMutableArray *anyArray;

@property NSMutableSet *boolSet;
@property NSMutableSet *intSet;
@property NSMutableSet *floatSet;
@property NSMutableSet *doubleSet;
@property NSMutableSet *stringSet;
@property NSMutableSet *dataSet;
@property NSMutableSet *dateSet;
@property NSMutableSet *objectSet;
@property NSMutableSet *objectIdSet;
@property NSMutableSet *decimal128Set;
@property NSMutableSet *uuidSet;
@property NSMutableSet *anySet;

@property NSMutableDictionary *boolDictionary;
@property NSMutableDictionary *intDictionary;
@property NSMutableDictionary *floatDictionary;
@property NSMutableDictionary *doubleDictionary;
@property NSMutableDictionary *stringDictionary;
@property NSMutableDictionary *dataDictionary;
@property NSMutableDictionary *dateDictionary;
@property NSMutableDictionary *objectDictionary;
@property NSMutableDictionary *objectIdDictionary;
@property NSMutableDictionary *decimal128Dictionary;
@property NSMutableDictionary *uuidDictionary;
@property NSMutableDictionary *anyDictionary;

@property NSNumber<RLMInt> *optIntCol;
@property NSNumber<RLMFloat> *optFloatCol;
@property NSNumber<RLMDouble> *optDoubleCol;
@property NSNumber<RLMBool> *optBoolCol;
@end
@implementation PlainKVOObject
@end

@interface PlainLinkObject1 : NSObject
@property PlainKVOObject *obj;
@property NSMutableArray *array;
@property NSMutableSet *set;
@property NSMutableDictionary *dictionary;
@end
@implementation PlainLinkObject1
@end

@interface PlainLinkObject2 : NSObject
@property PlainLinkObject1 *obj;
@property NSMutableArray *array;
@property NSMutableSet *set;
@property NSMutableDictionary *dictionary;
@end
@implementation PlainLinkObject2
@end

// Tables with no links (or backlinks) preserve the order of rows on
// insertion/deletion, while tables with links do not, so we need an object
// class known to have no links to test the ordered case
@interface ObjectWithNoLinksToOrFrom : RLMObject
@property int value;
@end
@implementation ObjectWithNoLinksToOrFrom
@end

// An object which removes a KVO registration when it's deallocated, for use
// as an associated object
@interface KVOUnregisterHelper : NSObject
@end
@implementation KVOUnregisterHelper {
    __unsafe_unretained id _obj;
    __unsafe_unretained id _observer;
    NSString *_keyPath;
}

+ (void)automaticallyUnregister:(id)observer object:(id)obj keyPath:(NSString *)keyPath {
    KVOUnregisterHelper *helper = [self new];
    helper->_observer = observer;
    helper->_obj = obj;
    helper->_keyPath = keyPath;
    objc_setAssociatedObject(obj, (__bridge void *)helper, helper, OBJC_ASSOCIATION_RETAIN);
}

- (void)dealloc {
    [_obj removeObserver:_observer forKeyPath:_keyPath];
}
@end

// A KVO observer which retains the given object until it observes a change
@interface ReleaseOnObservation : NSObject
@property (strong) id object;
@end
@implementation ReleaseOnObservation
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(__unused NSDictionary *)change
                       context:(void *)context
{
    [object removeObserver:self forKeyPath:keyPath context:context];
    _object = nil;
}
@end

@interface KVOTests : RLMTestCase
// get an object that should be observed for the given object being mutated
// used by some of the subclasses to observe a different accessor for the same row
- (id)observableForObject:(id)obj;
@end

// subscribes to kvo notifications on the passed object on creation, records
// all change notifications sent and makes them available in `notifications`,
// and automatically unsubscribes on destruction
class KVORecorder {
    id _observer;
    id _obj;
    NSString *_keyPath;
    RLMRealm *_mutationRealm;
    RLMRealm *_observationRealm;
    NSMutableArray *_notifications;

public:
    // construct a new recorder for the given `keyPath` on `obj`, using `observer`
    // as the NSObject helper to actually add as an observer
    KVORecorder(id observer, id obj, NSString *keyPath,
                int options = NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew)
    : _observer(observer)
    , _obj([observer observableForObject:obj])
    , _keyPath(keyPath)
    , _mutationRealm([obj respondsToSelector:@selector(realm)] ? (RLMRealm *)[obj realm] : nil)
    , _observationRealm([_obj respondsToSelector:@selector(realm)] ? (RLMRealm *)[_obj realm] : nil)
    , _notifications([NSMutableArray new])
    {
        [_obj addObserver:observer forKeyPath:keyPath options:options context:this];
    }

    ~KVORecorder() {
        @try {
            [_obj removeObserver:_observer forKeyPath:_keyPath context:this];
        }
        @catch (NSException *e) {
            XCTFail(@"%@", e.description);
        }
        XCTAssertEqual(0U, _notifications.count);
    }

    // record a single notification
    void operator()(NSString *key, id obj, NSDictionary *changeDictionary) {
        XCTAssertEqual(obj, _obj);
        XCTAssertEqualObjects(key, _keyPath);
        [_notifications addObject:[NSDictionary dictionaryWithDictionary:changeDictionary]];
    }

    // ensure that the observed object is updated for any changes made to the
    // object being mutated if they are different
    void refresh() {
        if (_mutationRealm != _observationRealm) {
            [_mutationRealm commitWriteTransaction];
            [_observationRealm refresh];
            [_mutationRealm beginWriteTransaction];
        }
    }

    NSDictionary *pop_front() {
        NSDictionary *value = [_notifications firstObject];
        if (value) {
            [_notifications removeObjectAtIndex:0U];
        }
        return value;
    }

    NSUInteger size() const {
        return _notifications.count;
    }

    bool empty() const {
        return _notifications.count == 0;
    }
};

// Assert that `recorder` has a notification at `index` and return it if so
#define AssertNotification(recorder) ([&]{ \
    (recorder).refresh(); \
    NSDictionary *value = recorder.pop_front(); \
    XCTAssertNotNil(value, @"Did not get a notification when expected"); \
    return value; \
})()

// Validate that `recorder` has at least one notification, and that the first
// notification is the expected one
#define AssertChanged(recorder, from, to) do { \
    if (NSDictionary *note = AssertNotification((recorder))) { \
        XCTAssertEqualObjects(@(NSKeyValueChangeSetting), note[NSKeyValueChangeKindKey]); \
        XCTAssertEqualObjects((from), note[NSKeyValueChangeOldKey]); \
        XCTAssertEqualObjects((to), note[NSKeyValueChangeNewKey]); \
    } \
    else { \
        return; \
    } \
} while (false)

#define AssertCollectionChanged(s) do { \
    AssertNotification(r); \
    XCTAssertTrue(r.empty()); \
} while (false)

// Validate that `r` has a notification with the given kind and changed indexes,
// remove it, and verify that there are no more notifications
#define AssertIndexChange(kind, indexes) do { \
    if (NSDictionary *note = AssertNotification(r)) { \
        XCTAssertEqual([note[NSKeyValueChangeKindKey] intValue], static_cast<int>(kind)); \
        XCTAssertEqualObjects(note[NSKeyValueChangeIndexesKey], indexes); \
    } \
    XCTAssertTrue(r.empty()); \
} while (0)

// Tests for plain Foundation key-value observing to verify that we correctly
// match the standard semantics. Each of the subclasses of KVOTests runs the
// same set of tests on RLMObjects in difference scenarios
@implementation KVOTests
// forward a KVO notification to the KVORecorder stored in the context
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    (*static_cast<KVORecorder *>(context))(keyPath, object, change);
}

// overridden in the multiple accessors, one realm and multiple realms cases
- (id)observableForObject:(id)obj {
    return obj;
}

// overridden in the multiple realms case because `-refresh` does not send
// notifications for intermediate states
- (bool)collapsesNotifications {
    return false;
}

// overridden in all subclases to return the appropriate object
// base class runs the tests on a plain NSObject using stock KVO to ensure that
// the tests are actually covering the correct behavior, since there's a great
// deal that the documentation doesn't specify
- (id)createObject {
    PlainKVOObject *obj = [PlainKVOObject new];
    obj.int16Col = 1;
    obj.int32Col = 2;
    obj.int64Col = 3;
    obj.binaryCol = NSData.data;
    obj.stringCol = @"";
    obj.dateCol = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    obj.boolArray = [NSMutableArray array];
    obj.intArray = [NSMutableArray array];
    obj.floatArray = [NSMutableArray array];
    obj.doubleArray = [NSMutableArray array];
    obj.stringArray = [NSMutableArray array];
    obj.dataArray = [NSMutableArray array];
    obj.dateArray = [NSMutableArray array];
    obj.objectIdArray = [NSMutableArray array];
    obj.decimal128Array = [NSMutableArray array];
    obj.objectArray = [NSMutableArray array];
    obj.uuidArray = [NSMutableArray array];
    obj.anyArray = [NSMutableArray array];

    obj.boolSet = [NSMutableSet set];
    obj.intSet = [NSMutableSet set];
    obj.floatSet = [NSMutableSet set];
    obj.doubleSet = [NSMutableSet set];
    obj.stringSet = [NSMutableSet set];
    obj.dataSet = [NSMutableSet set];
    obj.dateSet = [NSMutableSet set];
    obj.objectIdSet = [NSMutableSet set];
    obj.decimal128Set = [NSMutableSet set];
    obj.objectSet = [NSMutableSet set];
    obj.uuidSet = [NSMutableSet set];
    obj.anySet = [NSMutableSet set];

    obj.boolDictionary = [NSMutableDictionary dictionary];
    obj.intDictionary = [NSMutableDictionary dictionary];
    obj.floatDictionary = [NSMutableDictionary dictionary];
    obj.doubleDictionary = [NSMutableDictionary dictionary];
    obj.stringDictionary = [NSMutableDictionary dictionary];
    obj.dataDictionary = [NSMutableDictionary dictionary];
    obj.dateDictionary = [NSMutableDictionary dictionary];
    obj.objectIdDictionary = [NSMutableDictionary dictionary];
    obj.decimal128Dictionary = [NSMutableDictionary dictionary];
    obj.objectDictionary = [NSMutableDictionary dictionary];
    obj.uuidDictionary = [NSMutableDictionary dictionary];
    obj.anyDictionary = [NSMutableDictionary dictionary];
    return obj;
}

- (id)createLinkObject {
    PlainLinkObject1 *obj1 = [PlainLinkObject1 new];
    obj1.obj = [self createObject];
    obj1.array = [NSMutableArray new];
    obj1.set = [NSMutableSet new];
    obj1.dictionary = [NSMutableDictionary new];

    PlainLinkObject2 *obj2 = [PlainLinkObject2 new];
    obj2.obj = obj1;
    obj2.array = [NSMutableArray new];
    obj2.set = [NSMutableSet new];
    obj2.dictionary = [NSMutableDictionary new];

    return obj2;
}

// actual tests follow

- (void)testRegisterForUnknownProperty {
    KVOObject *obj = [self createObject];

    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"non-existent" options:0 context:nullptr]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"non-existent"]);

    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"non-existent" options:NSKeyValueObservingOptionOld context:nullptr]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"non-existent"]);

    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"non-existent" options:NSKeyValueObservingOptionPrior context:nullptr]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"non-existent"]);
}

- (void)testRemoveObserver {
    // iOS 14.2 beta 2 has stopped throwing exceptions when a KVO observer is removed that does not exist
    // FIXME: revisit this once 14.2 is out to see if this was an intended change
#if REALM_PLATFORM_IOS
    if (@available(iOS 14.2, *)) {
        return;
    }
#endif

    KVOObject *obj = [self createObject];
    XCTAssertThrowsSpecificNamed([obj removeObserver:self forKeyPath:@"int32Col"], NSException, NSRangeException);
    XCTAssertThrowsSpecificNamed([obj removeObserver:self forKeyPath:@"int32Col" context:nullptr], NSException, NSRangeException);
    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:nullptr]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col"]);
    XCTAssertThrowsSpecificNamed([obj removeObserver:self forKeyPath:@"int32Col"], NSException, NSRangeException);

    // `context` parameter must match if it's passed, but the overload that doesn't
    // take one will unregister any context
    void *context1 = (void *)1;
    void *context2 = (void *)2;
    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context1]);
    XCTAssertThrows([obj removeObserver:self forKeyPath:@"int32Col" context:context2]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col" context:context1]);

    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context2]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col" context:context2]);

    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context2]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col"]);
    XCTAssertThrows([obj removeObserver:self forKeyPath:@"int32Col"]);

    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context1]);
    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context2]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col" context:context1]);
    XCTAssertThrows([obj removeObserver:self forKeyPath:@"int32Col" context:context1]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col" context:context2]);
    XCTAssertThrows([obj removeObserver:self forKeyPath:@"int32Col" context:context2]);

    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context1]);
    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context2]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col" context:context2]);
    XCTAssertThrows([obj removeObserver:self forKeyPath:@"int32Col" context:context2]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col" context:context1]);
    XCTAssertThrows([obj removeObserver:self forKeyPath:@"int32Col" context:context1]);

    // no context version should only unregister one (unspecified) observer
    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context1]);
    XCTAssertNoThrow([obj addObserver:self forKeyPath:@"int32Col" options:0 context:context2]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col"]);
    XCTAssertNoThrow([obj removeObserver:self forKeyPath:@"int32Col"]);
    XCTAssertThrows([obj removeObserver:self forKeyPath:@"int32Col"]);
}

- (void)testRemoveObserverInObservation {
    auto helper = [ReleaseOnObservation new];

    __unsafe_unretained id obj;
    __weak id weakObj;
    @autoreleasepool {
        obj = weakObj = helper.object = [self createObject];
        [obj addObserver:helper forKeyPath:@"int32Col" options:NSKeyValueObservingOptionOld context:nullptr];
    }

    [obj setInt32Col:0];
    XCTAssertNil(helper.object);
    XCTAssertNil(weakObj);
}

- (void)testSimple {
    KVOObject *obj = [self createObject];
    {
        KVORecorder r(self, obj, @"int32Col");
        obj.int32Col = 10;
        AssertChanged(r, @2, @10);
    }
    {
        KVORecorder r(self, obj, @"int32Col");
        obj.int32Col = 1;
        AssertChanged(r, @10, @1);
    }
}

- (void)testSelfAssignmentNotifies {
    KVOObject *obj = [self createObject];
    {
        KVORecorder r(self, obj, @"int32Col");
        obj.int32Col = obj.int32Col;
        AssertChanged(r, @2, @2);
    }
}

- (void)testMultipleObserversAreNotified {
    KVOObject *obj = [self createObject];
    {
        KVORecorder r1(self, obj, @"int32Col");
        KVORecorder r2(self, obj, @"int32Col");
        KVORecorder r3(self, obj, @"int32Col");
        obj.int32Col = 10;
        AssertChanged(r1, @2, @10);
        AssertChanged(r2, @2, @10);
        AssertChanged(r3, @2, @10);
    }
}

- (void)testOnlyObserversForTheCorrectPropertyAreNotified {
    KVOObject *obj = [self createObject];
    {
        KVORecorder r16(self, obj, @"int16Col");
        KVORecorder r32(self, obj, @"int32Col");
        KVORecorder r64(self, obj, @"int64Col");

        obj.int16Col = 2;
        AssertChanged(r16, @1, @2);
        XCTAssertTrue(r16.empty());
        XCTAssertTrue(r32.empty());
        XCTAssertTrue(r64.empty());

        obj.int32Col = 2;
        AssertChanged(r32, @2, @2);
        XCTAssertTrue(r16.empty());
        XCTAssertTrue(r32.empty());
        XCTAssertTrue(r64.empty());

        obj.int64Col = 2;
        AssertChanged(r64, @3, @2);
        XCTAssertTrue(r16.empty());
        XCTAssertTrue(r32.empty());
        XCTAssertTrue(r64.empty());
    }
}

- (void)testMultipleChangesWithSingleObserver {
    KVOObject *obj = [self createObject];
    KVORecorder r(self, obj, @"int32Col");

    obj.int32Col = 1;
    obj.int32Col = 2;
    obj.int32Col = 3;
    obj.int32Col = 3;

    if (self.collapsesNotifications) {
        AssertChanged(r, @2, @3);
    }
    else {
        AssertChanged(r, @2, @1);
        AssertChanged(r, @1, @2);
        AssertChanged(r, @2, @3);
        AssertChanged(r, @3, @3);
    }
}

- (void)testOnlyObserversForTheCorrectObjectAreNotified {
    KVOObject *obj1 = [self createObject];
    KVOObject *obj2 = [self createObject];

    KVORecorder r1(self, obj1, @"int32Col");
    KVORecorder r2(self, obj2, @"int32Col");

    obj1.int32Col = 10;
    AssertChanged(r1, @2, @10);
    XCTAssertEqual(0U, r2.size());

    obj2.int32Col = 5;
    AssertChanged(r2, @2, @5);
}

- (void)testOptionsInitial {
    KVOObject *obj = [self createObject];

    {
        KVORecorder r(self, obj, @"int32Col", 0);
        XCTAssertEqual(0U, r.size());
    }
    {
        KVORecorder r(self, obj, @"int32Col", NSKeyValueObservingOptionInitial);
        r.pop_front();
    }
}

- (void)testOptionsOld {
    KVOObject *obj = [self createObject];

    {
        KVORecorder r(self, obj, @"int32Col", 0);
        obj.int32Col = 0;
        if (NSDictionary *note = AssertNotification(r)) {
            XCTAssertNil(note[NSKeyValueChangeOldKey]);
        }
    }
    {
        KVORecorder r(self, obj, @"int32Col", NSKeyValueObservingOptionOld);
        obj.int32Col = 0;
        if (NSDictionary *note = AssertNotification(r)) {
            XCTAssertNotNil(note[NSKeyValueChangeOldKey]);
        }
    }
}

- (void)testOptionsNew {
    KVOObject *obj = [self createObject];

    {
        KVORecorder r(self, obj, @"int32Col", 0);
        obj.int32Col = 0;
        if (NSDictionary *note = AssertNotification(r)) {
            XCTAssertNil(note[NSKeyValueChangeNewKey]);
        }
    }
    {
        KVORecorder r(self, obj, @"int32Col", NSKeyValueObservingOptionNew);
        obj.int32Col = 0;
        if (NSDictionary *note = AssertNotification(r)) {
            XCTAssertNotNil(note[NSKeyValueChangeNewKey]);
        }
    }
}

- (void)testOptionsPrior {
    KVOObject *obj = [self createObject];

    KVORecorder r(self, obj, @"int32Col", NSKeyValueObservingOptionNew|NSKeyValueObservingOptionPrior);
    obj.int32Col = 0;
    r.refresh();

    XCTAssertEqual(2U, r.size());
    if (NSDictionary *note = AssertNotification(r)) {
        XCTAssertNil(note[NSKeyValueChangeNewKey]);
        XCTAssertEqualObjects(@YES, note[NSKeyValueChangeNotificationIsPriorKey]);
    }
    if (NSDictionary *note = AssertNotification(r)) {
        XCTAssertNotNil(note[NSKeyValueChangeNewKey]);
        XCTAssertNil(note[NSKeyValueChangeNotificationIsPriorKey]);
    }
}

- (void)testAllPropertyTypes {
    KVOObject *obj = [self createObject];

    {
        KVORecorder r(self, obj, @"boolCol");
        obj.boolCol = YES;
        AssertChanged(r, @NO, @YES);
    }

    {
        KVORecorder r(self, obj, @"int16Col");
        obj.int16Col = 0;
        AssertChanged(r, @1, @0);
    }

    {
        KVORecorder r(self, obj, @"int32Col");
        obj.int32Col = 0;
        AssertChanged(r, @2, @0);
    }

    {
        KVORecorder r(self, obj, @"int64Col");
        obj.int64Col = 0;
        AssertChanged(r, @3, @0);
    }

    {
        KVORecorder r(self, obj, @"floatCol");
        obj.floatCol = 1.0f;
        AssertChanged(r, @0, @1);
    }

    {
        KVORecorder r(self, obj, @"doubleCol");
        obj.doubleCol = 1.0;
        AssertChanged(r, @0, @1);
    }

    {
        KVORecorder r(self, obj, @"cBoolCol");
        obj.cBoolCol = YES;
        AssertChanged(r, @NO, @YES);
    }

    {
        KVORecorder r(self, obj, @"stringCol");
        obj.stringCol = @"abc";
        AssertChanged(r, @"", @"abc");
        obj.stringCol = nil;
        AssertChanged(r, @"abc", NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"binaryCol");
        NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
        obj.binaryCol = data;
        AssertChanged(r, NSData.data, data);
        obj.binaryCol = nil;
        AssertChanged(r, data, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"dateCol");
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:1];
        obj.dateCol = date;
        AssertChanged(r, [NSDate dateWithTimeIntervalSinceReferenceDate:0], date);
        obj.dateCol = nil;
        AssertChanged(r, date, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"objectIdCol");
        RLMObjectId *objectId = [RLMObjectId objectId];
        obj.objectIdCol = objectId;
        AssertChanged(r, NSNull.null, objectId);
        obj.objectIdCol = nil;
        AssertChanged(r, objectId, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"decimal128Col");
        RLMDecimal128 *decimal128 = [[RLMDecimal128 alloc] initWithNumber:@1];
        obj.decimal128Col = decimal128;
        AssertChanged(r, NSNull.null, decimal128);
        obj.decimal128Col = nil;
        AssertChanged(r, decimal128, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"objectCol");
        obj.objectCol = obj;
        AssertChanged(r, NSNull.null, [self observableForObject:obj]);
        obj.objectCol = nil;
        AssertChanged(r, [self observableForObject:obj], NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"uuidCol");
        NSUUID *uuid = [NSUUID UUID];
        obj.uuidCol = uuid;
        AssertChanged(r, NSNull.null, uuid);
        obj.uuidCol = nil;
        AssertChanged(r, uuid, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"anyCol");
        obj.anyCol = @"abc";
        AssertChanged(r, NSNull.null, @"abc");
        obj.anyCol = nil;
        AssertChanged(r, @"abc", NSNull.null);
    }
    // Array
    {
        KVORecorder r(self, obj, @"intArray");
        obj.intArray = obj.intArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"boolArray");
        obj.boolArray = obj.boolArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"floatArray");
        obj.floatArray = obj.floatArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"doubleArray");
        obj.doubleArray = obj.doubleArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"stringArray");
        obj.stringArray = obj.stringArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"dataArray");
        obj.dataArray = obj.dataArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"dateArray");
        obj.dateArray = obj.dateArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"objectIdArray");
        obj.objectIdArray = obj.objectIdArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"decimal128Array");
        obj.decimal128Array = obj.decimal128Array;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"objectArray");
        obj.objectArray = obj.objectArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"uuidArray");
        obj.uuidArray = obj.uuidArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"anyArray");
        obj.anyArray = obj.anyArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }
    // Set
    {
        KVORecorder r(self, obj, @"intSet");
        obj.intSet = obj.intSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"boolSet");
        obj.boolSet = obj.boolSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"floatSet");
        obj.floatSet = obj.floatSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"doubleSet");
        obj.doubleSet = obj.doubleSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"stringSet");
        obj.stringSet = obj.stringSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"dataSet");
        obj.dataSet = obj.dataSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"dateSet");
        obj.dateSet = obj.dateSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"objectIdSet");
        obj.objectIdSet = obj.objectIdSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"decimal128Set");
        obj.decimal128Set = obj.decimal128Set;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"objectSet");
        obj.objectSet = obj.objectSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"uuidSet");
        obj.uuidSet = obj.uuidSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"anySet");
        obj.anySet = obj.anySet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }
    // Dictionary
    {
        KVORecorder r(self, obj, @"intDictionary");
        obj.intDictionary = obj.intDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"boolDictionary");
        obj.boolDictionary = obj.boolDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"floatDictionary");
        obj.floatDictionary = obj.floatDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"doubleDictionary");
        obj.doubleDictionary = obj.doubleDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"stringDictionary");
        obj.stringDictionary = obj.stringDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"dataDictionary");
        obj.dataDictionary = obj.dataDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"dateDictionary");
        obj.dateDictionary = obj.dateDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"objectIdDictionary");
        obj.objectIdDictionary = obj.objectIdDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"decimal128Dictionary");
        obj.decimal128Dictionary = obj.decimal128Dictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"objectDictionary");
        obj.objectDictionary = obj.objectDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"uuidDictionary");
        obj.uuidDictionary = obj.uuidDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"anyDictionary");
        obj.anyDictionary = obj.anyDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"optIntCol");
        obj.optIntCol = @1;
        AssertChanged(r, NSNull.null, @1);
        obj.optIntCol = nil;
        AssertChanged(r, @1, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optFloatCol");
        obj.optFloatCol = @1.1f;
        AssertChanged(r, NSNull.null, @1.1f);
        obj.optFloatCol = nil;
        AssertChanged(r, @1.1f, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optDoubleCol");
        obj.optDoubleCol = @1.1;
        AssertChanged(r, NSNull.null, @1.1);
        obj.optDoubleCol = nil;
        AssertChanged(r, @1.1, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optBoolCol");
        obj.optBoolCol = @YES;
        AssertChanged(r, NSNull.null, @YES);
        obj.optBoolCol = nil;
        AssertChanged(r, @YES, NSNull.null);
    }
}

- (void)testAllPropertyTypesKVC {
    KVOObject *obj = [self createObject];

    {
        KVORecorder r(self, obj, @"boolCol");
        [obj setValue:@YES forKey:@"boolCol"];
        AssertChanged(r, @NO, @YES);
    }

    {
        KVORecorder r(self, obj, @"int16Col");
        [obj setValue:@0 forKey:@"int16Col"];
        AssertChanged(r, @1, @0);
    }

    {
        KVORecorder r(self, obj, @"int32Col");
        [obj setValue:@0 forKey:@"int32Col"];
        AssertChanged(r, @2, @0);
    }

    {
        KVORecorder r(self, obj, @"int64Col");
        [obj setValue:@0 forKey:@"int64Col"];
        AssertChanged(r, @3, @0);
    }

    {
        KVORecorder r(self, obj, @"floatCol");
        [obj setValue:@1.0f forKey:@"floatCol"];
        AssertChanged(r, @0, @1);
    }

    {
        KVORecorder r(self, obj, @"doubleCol");
        [obj setValue:@1.0 forKey:@"doubleCol"];
        AssertChanged(r, @0, @1);
    }

    {
        KVORecorder r(self, obj, @"cBoolCol");
        [obj setValue:@YES forKey:@"cBoolCol"];
        AssertChanged(r, @NO, @YES);
    }

    {
        KVORecorder r(self, obj, @"stringCol");
        [obj setValue:@"abc" forKey:@"stringCol"];
        AssertChanged(r, @"", @"abc");
        [obj setValue:nil forKey:@"stringCol"];
        AssertChanged(r, @"abc", NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"binaryCol");
        NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
        [obj setValue:data forKey:@"binaryCol"];
        AssertChanged(r, NSData.data, data);
        [obj setValue:nil forKey:@"binaryCol"];
        AssertChanged(r, data, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"dateCol");
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:1];
        [obj setValue:date forKey:@"dateCol"];
        AssertChanged(r, [NSDate dateWithTimeIntervalSinceReferenceDate:0], date);
        [obj setValue:nil forKey:@"dateCol"];
        AssertChanged(r, date, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"objectIdCol");
        RLMObjectId *objectId = [RLMObjectId objectId];
        [obj setValue:objectId forKey:@"objectIdCol"];
        AssertChanged(r, NSNull.null, objectId);
        [obj setValue:nil forKey:@"objectIdCol"];
        AssertChanged(r, objectId, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"decimal128Col");
        RLMDecimal128 *decimal128 = [[RLMDecimal128 alloc] initWithNumber:@1];
        [obj setValue:decimal128 forKey:@"decimal128Col"];
        AssertChanged(r, NSNull.null, decimal128);
        [obj setValue:nil forKey:@"decimal128Col"];
        AssertChanged(r, decimal128, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"objectCol");
        [obj setValue:obj forKey:@"objectCol"];
        AssertChanged(r, NSNull.null, [self observableForObject:obj]);
        [obj setValue:nil forKey:@"objectCol"];
        AssertChanged(r, [self observableForObject:obj], NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"uuidCol");
        NSUUID *uuid = [NSUUID UUID];
        [obj setValue:uuid forKey:@"uuidCol"];
        AssertChanged(r, NSNull.null, uuid);
        [obj setValue:nil forKey:@"uuidCol"];
        AssertChanged(r, uuid, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"objectArray");
        [obj setValue:obj.objectArray forKey:@"objectArray"];
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"optIntCol");
        [obj setValue:@1 forKey:@"optIntCol"];
        AssertChanged(r, NSNull.null, @1);
        [obj setValue:nil forKey:@"optIntCol"];
        AssertChanged(r, @1, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optFloatCol");
        [obj setValue:@1.1f forKey:@"optFloatCol"];
        AssertChanged(r, NSNull.null, @1.1f);
        [obj setValue:nil forKey:@"optFloatCol"];
        AssertChanged(r, @1.1f, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optDoubleCol");
        [obj setValue:@1.1 forKey:@"optDoubleCol"];
        AssertChanged(r, NSNull.null, @1.1);
        [obj setValue:nil forKey:@"optDoubleCol"];
        AssertChanged(r, @1.1, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optBoolCol");
        [obj setValue:@YES forKey:@"optBoolCol"];
        AssertChanged(r, NSNull.null, @YES);
        [obj setValue:nil forKey:@"optBoolCol"];
        AssertChanged(r, @YES, NSNull.null);
    }
}

- (void)testAllPropertyTypesDynamic {
    KVOObject *obj = [self createObject];
    if (![obj respondsToSelector:@selector(setObject:forKeyedSubscript:)]) {
        return;
    }

    {
        KVORecorder r(self, obj, @"boolCol");
        obj[@"boolCol"] = @YES;
        AssertChanged(r, @NO, @YES);
    }

    {
        KVORecorder r(self, obj, @"int16Col");
        obj[@"int16Col"] = @0;
        AssertChanged(r, @1, @0);
    }

    {
        KVORecorder r(self, obj, @"int32Col");
        obj[@"int32Col"] = @0;
        AssertChanged(r, @2, @0);
    }

    {
        KVORecorder r(self, obj, @"int64Col");
        obj[@"int64Col"] = @0;
        AssertChanged(r, @3, @0);
    }

    {
        KVORecorder r(self, obj, @"floatCol");
        obj[@"floatCol"] = @1.0f;
        AssertChanged(r, @0, @1);
    }

    {
        KVORecorder r(self, obj, @"doubleCol");
        obj[@"doubleCol"] = @1.0;
        AssertChanged(r, @0, @1);
    }

    {
        KVORecorder r(self, obj, @"cBoolCol");
        obj[@"cBoolCol"] = @YES;
        AssertChanged(r, @NO, @YES);
    }

    {
        KVORecorder r(self, obj, @"stringCol");
        obj[@"stringCol"] = @"abc";
        AssertChanged(r, @"", @"abc");
        obj[@"stringCol"] = nil;
        AssertChanged(r, @"abc", NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"binaryCol");
        NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
        obj[@"binaryCol"] = data;
        AssertChanged(r, NSData.data, data);
        obj[@"binaryCol"] = nil;
        AssertChanged(r, data, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"dateCol");
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:1];
        obj[@"dateCol"] = date;
        AssertChanged(r, [NSDate dateWithTimeIntervalSinceReferenceDate:0], date);
        obj[@"dateCol"] = nil;
        AssertChanged(r, date, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"objectCol");
        obj[@"objectCol"] = obj;
        AssertChanged(r, NSNull.null, [self observableForObject:obj]);
        obj[@"objectCol"] = nil;
        AssertChanged(r, [self observableForObject:obj], NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"uuidCol");
        NSUUID *uuid = [NSUUID UUID];
        obj[@"uuidCol"] = uuid;
        AssertChanged(r, NSNull.null, uuid);
        obj[@"uuidCol"] = nil;
        AssertChanged(r, uuid, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"anyCol");
        obj[@"anyCol"] = @"abc";
        AssertChanged(r, NSNull.null, @"abc");
        obj[@"anyCol"] = nil;
        AssertChanged(r, @"abc", NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"objectArray");
        obj[@"objectArray"] = obj.objectArray;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"objectSet");
        obj[@"objectSet"] = obj.objectSet;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"objectDictionary");
        obj[@"objectDictionary"] = obj.objectDictionary;
        r.refresh();
        r.pop_front(); // asserts that there's something to pop
    }

    {
        KVORecorder r(self, obj, @"optIntCol");
        obj[@"optIntCol"] = @1;
        AssertChanged(r, NSNull.null, @1);
        obj[@"optIntCol"] = nil;
        AssertChanged(r, @1, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optFloatCol");
        obj[@"optFloatCol"] = @1.1f;
        AssertChanged(r, NSNull.null, @1.1f);
        obj[@"optFloatCol"] = nil;
        AssertChanged(r, @1.1f, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optDoubleCol");
        obj[@"optDoubleCol"] = @1.1;
        AssertChanged(r, NSNull.null, @1.1);
        obj[@"optDoubleCol"] = nil;
        AssertChanged(r, @1.1, NSNull.null);
    }

    {
        KVORecorder r(self, obj, @"optBoolCol");
        obj[@"optBoolCol"] = @YES;
        AssertChanged(r, NSNull.null, @YES);
        obj[@"optBoolCol"] = nil;
        AssertChanged(r, @YES, NSNull.null);
    }
}

- (void)testArrayDiffs {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"array");

    id mutator = [obj mutableArrayValueForKey:@"array"];

    [mutator addObject:obj.obj];
    AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);

    [mutator addObject:obj.obj];
    AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:1]);

    [mutator removeObjectAtIndex:0];
    AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:0]);

    [mutator replaceObjectAtIndex:0 withObject:obj.obj];
    AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndex:0]);

    NSMutableIndexSet *indexes = [NSMutableIndexSet new];
    [indexes addIndex:0];
    [indexes addIndex:2];
    [mutator insertObjects:@[obj.obj, obj.obj] atIndexes:indexes];
    AssertIndexChange(NSKeyValueChangeInsertion, indexes);

    [mutator removeObjectsAtIndexes:indexes];
    AssertIndexChange(NSKeyValueChangeRemoval, indexes);

    if (![obj.array isKindOfClass:[NSArray class]]) {
        // We deliberately diverge from NSMutableArray for `removeAllObjects` and
        // `addObjectsFromArray:`, because generating a separate notification for
        // each object added or removed is needlessly pessimal.
        [mutator addObjectsFromArray:@[obj.obj, obj.obj]];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]);

        // NSArray sends multiple notifications for exchange, which we can't do
        // on refresh
        [mutator exchangeObjectAtIndex:0 withObjectAtIndex:1];
        AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);

        // NSArray doesn't have move
        [mutator moveObjectAtIndex:1 toIndex:0];
        AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);

        [mutator removeLastObject];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:2]);

        [mutator removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);
    }
}

- (void)testPrimitiveArrayDiffs {
    KVOObject *obj = [self createObject];
    KVORecorder r(self, obj, @"intArray");

    id mutator = [obj mutableArrayValueForKey:@"intArray"];

    [mutator addObject:@1];
    AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);

    [mutator addObject:@2];
    AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:1]);

    [mutator removeObjectAtIndex:0];
    AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:0]);

    [mutator replaceObjectAtIndex:0 withObject:@3];
    AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndex:0]);

    NSMutableIndexSet *indexes = [NSMutableIndexSet new];
    [indexes addIndex:0];
    [indexes addIndex:2];
    [mutator insertObjects:@[@4, @5] atIndexes:indexes];
    AssertIndexChange(NSKeyValueChangeInsertion, indexes);

    [mutator removeObjectsAtIndexes:indexes];
    AssertIndexChange(NSKeyValueChangeRemoval, indexes);

    if (![obj.intArray isKindOfClass:[NSArray class]]) {
        // We deliberately diverge from NSMutableArray for `removeAllObjects` and
        // `addObjectsFromArray:`, because generating a separate notification for
        // each object added or removed is needlessly pessimal.
        [mutator addObjectsFromArray:@[@6, @7]];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]);

        // NSArray sends multiple notifications for exchange, which we can't do
        // on refresh
        [mutator exchangeObjectAtIndex:0 withObjectAtIndex:1];
        AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);

        // NSArray doesn't have move
        [mutator moveObjectAtIndex:1 toIndex:0];
        AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);

        [mutator removeLastObject];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:2]);

        [mutator removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);
    }
}

- (void)testSetKVO {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject2 *obj2 = [self createLinkObject];
    KVORecorder r(self, obj, @"set");

    id mutator = [obj mutableSetValueForKey:@"set"];
    id mutator2 = [obj2 mutableSetValueForKey:@"set"];
    id set2 = [obj2 valueForKey:@"set"];

    [mutator addObject:obj.obj];
    AssertCollectionChanged();
    [mutator removeObject:obj.obj];
    AssertCollectionChanged();
    [mutator addObject:obj.obj];
    AssertCollectionChanged();
    [mutator2 addObject:obj2.obj];
    [mutator setSet:set2];
    AssertCollectionChanged();

    [mutator intersectSet:set2];
    AssertCollectionChanged();
    [mutator minusSet:set2];
    AssertCollectionChanged();
    [mutator unionSet:set2];
    AssertCollectionChanged();
}

- (void)testPrimitiveSetKVO {
    KVOObject *obj = [self createObject];
    KVOObject *obj2 = [self createObject];
    KVORecorder r(self, obj, @"intSet");

    id mutator = [obj mutableSetValueForKey:@"intSet"];
    id mutator2 = [obj2 mutableSetValueForKey:@"intSet"];

    [mutator addObject:@1];
    AssertCollectionChanged();
    [mutator removeObject:@1];
    AssertCollectionChanged();
    [mutator addObject:@1];
    AssertCollectionChanged();
    [mutator2 addObject:@2];
    [mutator setSet:mutator2];
    AssertCollectionChanged();

    [mutator intersectSet:mutator2];
    AssertCollectionChanged();
    [mutator minusSet:mutator2];
    AssertCollectionChanged();
    [mutator unionSet:mutator2];
    AssertCollectionChanged();
}

- (void)testDictionaryKVO {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject2 *obj2 = [self createLinkObject];
    KVORecorder r(self, obj, @"dictionary");

    id mutator = [obj valueForKey:@"dictionary"];
    id mutator2 = [obj2 valueForKey:@"dictionary"];

    // Foundation doesn't expose any notifying proxy classes for NSMutableDictionary
    // and it doesnt really make sense to create a wrapper purely for testing.
    // So if `mutator` is NSMutableDictionary return.

    if ([mutator isKindOfClass:[NSMutableDictionary class]]) {
        return;
    }

    [mutator setObject:obj.obj forKey:@"key"];
    AssertCollectionChanged();
    [mutator removeObjectForKey:@"key"];
    AssertCollectionChanged();
    [mutator setObject:obj.obj forKey:@"key2"];
    AssertCollectionChanged();
    [mutator2 setObject:obj2.obj forKey:@"key"];
    [mutator removeAllObjects];
    AssertCollectionChanged();
}

- (void)testPrimitiveDictionaryKVO {
    KVOObject *obj = [self createObject];
    KVOObject *obj2 = [self createObject];
    KVORecorder r(self, obj, @"intDictionary");

    id mutator = [obj valueForKey:@"intDictionary"];
    id mutator2 = [obj2 valueForKey:@"intDictionary"];

    if ([mutator isKindOfClass:[NSMutableDictionary class]]) {
        return;
    }

    [mutator setObject:@1 forKey:@"key"];
    AssertCollectionChanged();
    [mutator removeObjectForKey:@"key"];
    AssertCollectionChanged();
    [mutator setObject:@2 forKey:@"key2"];
    AssertCollectionChanged();
    [mutator2 setObject:@3 forKey:@"key"];
    [mutator removeAllObjects];
    AssertCollectionChanged();
}

- (void)testIgnoredProperty {
    KVOObject *obj = [self createObject];
    KVORecorder r(self, obj, @"ignored");
    obj.ignored = 10;
    AssertChanged(r, @0, @10);
}

- (void)testChangeEndOfKeyPath {
    KVOLinkObject2 *obj = [self createLinkObject];
    std::unique_ptr<KVORecorder> r;
    @autoreleasepool {
        r = std::make_unique<KVORecorder>(self, obj, @"obj.obj.boolCol");
    }
    obj.obj.obj.boolCol = YES;
    AssertChanged(*r, @NO, @YES);
}

- (void)testChangeMiddleOfKeyPath {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOObject *oldObj = obj.obj.obj;
    KVOObject *newObj = [self createObject];
    newObj.boolCol = YES;

    KVORecorder r(self, obj, @"obj.obj.boolCol");
    obj.obj.obj = newObj;
    AssertChanged(r, @NO, @YES);
    newObj.boolCol = NO;
    AssertChanged(r, @YES, @NO);
    oldObj.boolCol = YES;
}

- (void)testNullifyMiddleOfKeyPath {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"obj.obj.boolCol");
    obj.obj = nil;
    AssertChanged(r, @NO, NSNull.null);
}

- (void)testChangeMiddleOfKeyPathToNonNil {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject1 *obj2 = obj.obj;
    obj.obj = nil;
    obj2.obj.boolCol = YES;

    KVORecorder r(self, obj, @"obj.obj.boolCol");
    obj.obj = obj2;
    AssertChanged(r, NSNull.null, @YES);
}

- (void)testArrayKVC {
    KVOObject *obj = [self createObject];
    [obj.objectArray addObject:obj];

    KVORecorder r(self, obj, @"boolCol");
    [obj.objectArray setValue:@YES forKey:@"boolCol"];
    AssertChanged(r, @NO, @YES);
}

- (void)testSetKVC {
    KVOObject *obj = [self createObject];
    [obj.objectSet addObject:obj];

    KVORecorder r(self, obj, @"boolCol");
    [obj.objectSet setValue:@YES forKey:@"boolCol"];
    AssertChanged(r, @NO, @YES);
}

- (void)testSharedSchemaOnObservedObjectGivesOriginalSchema {
    KVOObject *obj = [self createObject];
    if (![obj isKindOfClass:RLMObjectBase.class]) {
        return;
    }

    RLMObjectSchema *original = [obj.class sharedSchema];
    KVORecorder r(self, obj, @"boolCol");
    XCTAssertEqual(original, [obj.class sharedSchema]); // note: intentionally not EqualObjects
}

// RLMArray doesn't support @count at all
- (void)testObserveArrayCount {
    KVOObject *obj = [self createObject];
    KVORecorder r(self, obj, @"objectArray.@count");
    id mutator = [obj mutableArrayValueForKey:@"objectArray"];
    [mutator addObject:obj];
    AssertChanged(r, @0, @1);
}
@end

// Run tests on an unmanaged RLMObject instance
@interface KVOUnmanagedObjectTests : KVOTests
@end
@implementation KVOUnmanagedObjectTests
- (id)createObject {
    static int pk = 0;
    KVOObject *obj = [KVOObject new];
    obj.pk = pk++;
    obj.int16Col = 1;
    obj.int32Col = 2;
    obj.int64Col = 3;
    obj.binaryCol = NSData.data;
    obj.stringCol = @"";
    obj.dateCol = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    return obj;
}

- (id)createLinkObject {
    static int pk = 0;
    KVOLinkObject1 *obj1 = [KVOLinkObject1 new];
    obj1.pk = pk++;
    obj1.obj = [self createObject];
    KVOLinkObject2 *obj2 = [KVOLinkObject2 new];
    obj2.pk = pk++;
    obj2.obj = obj1;
    return obj2;
}

- (void)testAddToRealmAfterAddingObservers {
    RLMRealm *realm = RLMRealm.defaultRealm;
    [realm beginWriteTransaction];

    KVOObject *obj = [self createObject];
    {
        KVORecorder r(self, obj, @"int32Col");
        XCTAssertThrows([realm addObject:obj]);
    }
    XCTAssertNoThrow([realm addObject:obj]);
    [realm cancelWriteTransaction];
}

- (void)testObserveInvalidArrayProperty {
    KVOObject *obj = [self createObject];
    XCTAssertThrows([obj.objectArray addObserver:self forKeyPath:@"self" options:0 context:0]);
    XCTAssertNoThrow([obj.objectArray addObserver:self forKeyPath:RLMInvalidatedKey options:0 context:0]);
    XCTAssertNoThrow([obj.objectArray removeObserver:self forKeyPath:RLMInvalidatedKey context:0]);
}

- (void)testUnregisteringViaAnAssociatedObject {
    @autoreleasepool {
        __attribute__((objc_precise_lifetime)) KVOObject *obj = [self createObject];
        [obj addObserver:self forKeyPath:@"boolCol" options:0 context:0];
        [KVOUnregisterHelper automaticallyUnregister:self object:obj keyPath:@"boolCol"];
    }
    // Throws if the unregistration doesn't succeed
}

@end

// Run tests on a managed object, modifying the actual object instance being
// observed
@interface KVOManagedObjectTests : KVOTests
@property (nonatomic, strong) RLMRealm *realm;
@end

@implementation KVOManagedObjectTests
- (void)setUp {
    [super setUp];
    _realm = [self getRealm];
    [_realm beginWriteTransaction];
}

- (void)tearDown {
    [self.realm cancelWriteTransaction];
    self.realm = nil;
    [super tearDown];
}

- (RLMRealm *)getRealm {
    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.inMemoryIdentifier = @"test";
    configuration.schemaMode = realm::SchemaMode::AdditiveDiscovered;
    return [RLMRealm realmWithConfiguration:configuration error:nil];
}

- (id)createObject {
    static std::atomic<int> pk{0};
    return [KVOObject createInRealm:_realm withValue:@[@(++pk),
                                                       @NO, @1, @2, @3, @0, @0, @NO, @"",
                                                       NSData.data, [NSDate dateWithTimeIntervalSinceReferenceDate:0]]];
}

- (id)createLinkObject {
    static std::atomic<int> pk{0};
    return [KVOLinkObject2 createInRealm:_realm withValue:@[@(++pk), @[@(++pk), [self createObject], @[]], @[]]];
}

- (EmbeddedIntParentObject *)createEmbeddedObject {
    return [EmbeddedIntParentObject createInRealm:_realm withValue:@[@1, @[@2], @[@[@3]]]];
}

- (void)testDeleteObservedObject {
    KVOObject *obj = [self createObject];
    KVORecorder r1(self, obj, @"boolCol");
    KVORecorder r2(self, obj, RLMInvalidatedKey);
    [self.realm deleteObject:obj];
    AssertChanged(r2, @NO, @YES);
    // should not crash
}

- (void)testDeleteMultipleObservedObjects {
    KVOObject *obj1 = [self createObject];
    KVOObject *obj2 = [self createObject];
    KVOObject *obj3 = [self createObject];

    KVORecorder r1(self, obj1, RLMInvalidatedKey);
    KVORecorder r2(self, obj2, RLMInvalidatedKey);
    KVORecorder r3(self, obj3, RLMInvalidatedKey);

    [self.realm deleteObject:obj2];
    AssertChanged(r2, @NO, @YES);
    XCTAssertTrue(r1.empty());
    XCTAssertTrue(r3.empty());

    [self.realm deleteObject:obj3];
    AssertChanged(r3, @NO, @YES);
    XCTAssertTrue(r1.empty());
    XCTAssertTrue(r2.empty());

    [self.realm deleteObject:obj1];
    AssertChanged(r1, @NO, @YES);
    XCTAssertTrue(r2.empty());
    XCTAssertTrue(r3.empty());
}

- (void)testDeleteMiddleOfKeyPath {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"obj.obj.boolCol");
    [self.realm deleteObject:obj.obj];
    AssertChanged(r, @NO, NSNull.null);
}

- (void)testDeleteParentOfObservedRLMArray {
    KVOObject *obj = [self createObject];
    KVORecorder r1(self, obj, @"objectArray");
    KVORecorder r2(self, obj, @"objectArray.invalidated");
    KVORecorder r3(self, obj.objectArray, RLMInvalidatedKey);
    [self.realm deleteObject:obj];
    AssertChanged(r2, @NO, @YES);
    AssertChanged(r3, @NO, @YES);
}

- (void)testDeleteAllObjects {
    KVOObject *obj = [self createObject];
    KVORecorder r1(self, obj, @"boolCol");
    KVORecorder r2(self, obj, RLMInvalidatedKey);
    [self.realm deleteAllObjects];
    AssertChanged(r2, @NO, @YES);
    // should not crash
}

- (void)testClearTable {
    KVOObject *obj = [self createObject];
    KVORecorder r1(self, obj, @"boolCol");
    KVORecorder r2(self, obj, RLMInvalidatedKey);
    [self.realm deleteObjects:[KVOObject allObjectsInRealm:self.realm]];
    AssertChanged(r2, @NO, @YES);
    // should not crash
}

- (void)testClearQuery {
    KVOObject *obj = [self createObject];
    KVORecorder r1(self, obj, @"boolCol");
    KVORecorder r2(self, obj, RLMInvalidatedKey);
    [self.realm deleteObjects:[KVOObject objectsInRealm:self.realm where:@"TRUEPREDICATE"]];
    AssertChanged(r2, @NO, @YES);
    // should not crash
}

- (void)testClearLinkView {
    KVOObject *obj = [self createObject];
    KVOObject *obj2 = [self createObject];
    [obj2.objectArray addObject:obj];

    KVORecorder r1(self, obj, @"boolCol");
    KVORecorder r2(self, obj, RLMInvalidatedKey);
    [self.realm deleteObjects:obj2.objectArray];
    AssertChanged(r2, @NO, @YES);
    // should not crash
}

- (void)testCreateObserverAfterDealloc {
    @autoreleasepool {
        KVOObject *obj = [self createObject];
        KVORecorder r(self, obj, @"boolCol");
        obj.boolCol = YES;
        AssertChanged(r, @NO, @YES);
    }
    @autoreleasepool {
        KVOObject *obj = [self createObject];
        KVORecorder r(self, obj, @"boolCol");
        obj.boolCol = YES;
        AssertChanged(r, @NO, @YES);
    }
}

- (void)testDirectlyDeleteLinkedToObject {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject1 *linked = obj.obj;
    KVORecorder r(self, obj, @"obj");
    KVORecorder r2(self, obj, @"obj.invalidated");
    [self.realm deleteObject:linked];

    if (NSDictionary *note = AssertNotification(r)) {
        XCTAssertTrue([note[NSKeyValueChangeOldKey] isKindOfClass:[RLMObjectBase class]]);
        XCTAssertEqualObjects(note[NSKeyValueChangeNewKey], NSNull.null);
    }
    AssertChanged(r2, @NO, NSNull.null);
}

- (void)testDeleteLinkedToObjectViaTableClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"obj");
    KVORecorder r2(self, obj, @"obj.invalidated");
    [self.realm deleteObjects:[KVOLinkObject1 allObjectsInRealm:self.realm]];

    if (NSDictionary *note = AssertNotification(r)) {
        XCTAssertTrue([note[NSKeyValueChangeOldKey] isKindOfClass:[RLMObjectBase class]]);
        XCTAssertEqualObjects(note[NSKeyValueChangeNewKey], NSNull.null);
    }
    AssertChanged(r2, @NO, NSNull.null);
}

- (void)testDeleteLinkedToObjectViaQueryClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"obj");
    KVORecorder r2(self, obj, @"obj.invalidated");
    [self.realm deleteObjects:[KVOLinkObject1 objectsInRealm:self.realm where:@"TRUEPREDICATE"]];

    if (NSDictionary *note = AssertNotification(r)) {
        XCTAssertTrue([note[NSKeyValueChangeOldKey] isKindOfClass:[RLMObjectBase class]]);
        XCTAssertEqualObjects(note[NSKeyValueChangeNewKey], NSNull.null);
    }
    AssertChanged(r2, @NO, NSNull.null);
}

- (void)testDeleteObjectInArray {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject1 *linked = obj.obj;
    [obj.array addObject:linked];
    KVORecorder r(self, obj, @"array");
    [self.realm deleteObject:linked];
    AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:0]);
}

- (void)testDeleteObjectsInArrayViaTableClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject2 *obj2 = [self createLinkObject];
    [obj.array addObject:obj.obj];
    [obj.array addObject:obj.obj];
    [obj.array addObject:obj2.obj];

    KVORecorder r(self, obj, @"array");
    [self.realm deleteObjects:[KVOLinkObject1 allObjectsInRealm:self.realm]];
    AssertIndexChange(NSKeyValueChangeRemoval, ([NSIndexSet indexSetWithIndexesInRange:{0, 3}]));
}

- (void)testDeleteObjectsInArrayViaTableViewClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject2 *obj2 = [self createLinkObject];
    [obj.array addObject:obj2.obj];
    [obj.array addObject:obj.obj];
    [obj.array addObject:obj.obj];

    KVORecorder r(self, obj, @"array");
    RLMResults *results = [KVOLinkObject1 objectsInRealm:self.realm where:@"TRUEPREDICATE"];
    [results lastObject];
    [self.realm deleteObjects:results];
    AssertIndexChange(NSKeyValueChangeRemoval, ([NSIndexSet indexSetWithIndexesInRange:{0, 3}]));
}

- (void)testDeleteObjectsInArrayViaQueryClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject2 *obj2 = [self createLinkObject];
    [obj.array addObject:obj.obj];
    [obj.array addObject:obj.obj];
    [obj.array addObject:obj2.obj];

    KVORecorder r(self, obj, @"array");
    [self.realm deleteObjects:[KVOLinkObject1 objectsInRealm:self.realm where:@"TRUEPREDICATE"]];
    AssertIndexChange(NSKeyValueChangeRemoval, ([NSIndexSet indexSetWithIndexesInRange:{0, 3}]));
}

- (void)testObserveInvalidArrayProperty {
    KVOObject *obj = [self createObject];
    RLMArray *array = obj.objectArray;
    XCTAssertThrows([array addObserver:self forKeyPath:@"self" options:0 context:0]);
    XCTAssertNoThrow([array addObserver:self forKeyPath:RLMInvalidatedKey options:0 context:0]);
    XCTAssertNoThrow([array removeObserver:self forKeyPath:RLMInvalidatedKey context:0]);
}

- (void)testInvalidOperationOnObservedArray {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject1 *linked = obj.obj;
    [obj.array addObject:linked];
    KVORecorder r(self, obj, @"array");
    XCTAssertThrows([obj.array exchangeObjectAtIndex:2 withObjectAtIndex:3]);
    // A KVO notification is still sent to observers on the same thread since we
    // can't cancel willChange, but the data is not very meaningful so don't check it
    if (!self.collapsesNotifications) {
        AssertNotification(r);
    }
}

- (void)testDeleteObjectInSet {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject1 *linked = obj.obj;
    [obj.set addObject:linked];
    KVORecorder r(self, obj, @"set");
    [self.realm deleteObject:linked];
    AssertCollectionChanged();
}

- (void)testDeleteObjectsInSetViaTableClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"set");

    [obj.set addObject:obj.obj];
    AssertCollectionChanged();

    [self.realm deleteObjects:[KVOLinkObject1 allObjectsInRealm:self.realm]];
    AssertCollectionChanged();
}

- (void)testDeleteObjectsInSetViaTableViewClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject2 *obj2 = [self createLinkObject];
    KVORecorder r(self, obj, @"set");
    [obj.set addObject:obj2.obj];
    AssertCollectionChanged();

    RLMResults *results = [KVOLinkObject1 objectsInRealm:self.realm where:@"TRUEPREDICATE"];
    [results lastObject];
    [self.realm deleteObjects:results];
    AssertCollectionChanged();
}

- (void)testDeleteObjectsInSetViaQueryClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"set");
    [obj.set addObject:obj.obj];
    AssertCollectionChanged();

    [self.realm deleteObjects:[KVOLinkObject1 objectsInRealm:self.realm where:@"TRUEPREDICATE"]];
    AssertCollectionChanged();
}

- (void)testObserveInvalidSetProperty {
    KVOObject *obj = [self createObject];
    RLMSet *set = obj.objectSet;
    XCTAssertThrows([set addObserver:self forKeyPath:@"self" options:0 context:0]);
    XCTAssertNoThrow([set addObserver:self forKeyPath:RLMInvalidatedKey options:0 context:0]);
    XCTAssertNoThrow([set removeObserver:self forKeyPath:RLMInvalidatedKey context:0]);
}

- (void)testInvalidOperationOnObservedSet {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject1 *linked = obj.obj;
    [obj.set addObject:linked];
    KVORecorder r(self, obj, @"set");
    XCTAssertThrows([obj.set addObject:(id)@1]);
    // A KVO notification is still sent to observers on the same thread since we
    // can't cancel willChange, but the data is not very meaningful so don't check it
    if (!self.collapsesNotifications) {
        AssertNotification(r);
    }
}

- (void)testDeleteObjectInDictionary {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject1 *linked = obj.obj;
    [obj.dictionary setObject:linked forKey:@"key"];
    KVORecorder r(self, obj, @"dictionary");
    [self.realm deleteObject:linked];
    AssertCollectionChanged();
}

- (void)testDeleteObjectsInDictionaryViaTableClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"dictionary");

    [obj.dictionary setObject:obj.obj forKey:@"key"];
    AssertCollectionChanged();

    [self.realm deleteObjects:[KVOLinkObject1 allObjectsInRealm:self.realm]];
    AssertCollectionChanged();
}

- (void)testDeleteObjectsInDictionaryViaTableViewClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVOLinkObject2 *obj2 = [self createLinkObject];
    KVORecorder r(self, obj, @"dictionary");
    [obj.dictionary setObject:obj2.obj forKey:@"key"];
    AssertCollectionChanged();

    RLMResults *results = [KVOLinkObject1 objectsInRealm:self.realm where:@"TRUEPREDICATE"];
    [results lastObject];
    [self.realm deleteObjects:results];
    AssertCollectionChanged();
}

- (void)testDeleteObjectsInDictionaryViaQueryClear {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"dictionary");
    [obj.dictionary setObject:obj.obj forKey:@"key"];
    AssertCollectionChanged();

    [self.realm deleteObjects:[KVOLinkObject1 objectsInRealm:self.realm where:@"TRUEPREDICATE"]];
    AssertCollectionChanged();
}

- (void)testObserveInvalidDictionaryProperty {
    KVOObject *obj = [self createObject];
    RLMDictionary *dictionary = obj.objectDictionary;
    XCTAssertThrows([dictionary addObserver:self forKeyPath:@"self" options:0 context:0]);
    XCTAssertNoThrow([dictionary addObserver:self forKeyPath:RLMInvalidatedKey options:0 context:0]);
    XCTAssertNoThrow([dictionary removeObserver:self forKeyPath:RLMInvalidatedKey context:0]);
}

- (void)testInvalidOperationOnObservedDictionary {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"dictionary");
    XCTAssertThrows([obj.dictionary setObject:(id)@1 forKey:@"key"]);
    // A KVO notification is still sent to observers on the same thread since we
    // can't cancel willChange, but the data is not very meaningful so don't check it
    if (!self.collapsesNotifications) {
        AssertNotification(r);
    }
}

- (void)testDeleteParentOfObservedEmbeddedObject {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r1(self, obj, @"object");
    KVORecorder r2(self, obj, @"object.invalidated");
    KVORecorder r3(self, obj.object, RLMInvalidatedKey);
    [self.realm deleteObject:obj];
    AssertChanged(r2, @NO, @YES);
    AssertChanged(r3, @NO, @YES);
}

- (void)testSetLinkToEmbeddedObjectToNil {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r1(self, obj, @"object.invalidated");
    KVORecorder r2(self, obj.object, RLMInvalidatedKey);
    obj.object = nil;

    AssertChanged(r1, @NO, NSNull.null);
    AssertChanged(r2, @NO, @YES);
}

- (void)testSetLinkToEmbeddedObjectToNewObject {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r1(self, obj, @"object.invalidated");
    KVORecorder r2(self, obj.object, RLMInvalidatedKey);
    obj.object = [[EmbeddedIntObject alloc] init];

    AssertChanged(r1, @NO, @NO);
    AssertChanged(r2, @NO, @YES);
}

- (void)testDynamicSetLinkToEmbeddedObjectToNil {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r1(self, obj, @"object.invalidated");
    KVORecorder r2(self, obj.object, RLMInvalidatedKey);
    obj[@"object"] = nil;

    AssertChanged(r1, @NO, NSNull.null);
    AssertChanged(r2, @NO, @YES);
}

- (void)testDynamicSetLinkToEmbeddedObjectToNewObject {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r1(self, obj, @"object.invalidated");
    KVORecorder r2(self, obj.object, RLMInvalidatedKey);
    obj[@"object"] = [[EmbeddedIntObject alloc] init];

    AssertChanged(r1, @NO, @NO);
    AssertChanged(r2, @NO, @YES);
}

- (void)testRemoveEmbeddedObjectFromArray {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r(self, obj.array[0], RLMInvalidatedKey);
    [obj.array removeAllObjects];
    AssertChanged(r, @NO, @YES);
}

- (void)testOverwriteEmbeddedObjectInArray {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r(self, obj, @"array");
    KVORecorder r2(self, obj.array[0], RLMInvalidatedKey);
    obj.array[0] = [[EmbeddedIntObject alloc] init];
    AssertIndexChange(NSKeyValueChangeReplacement, ([NSIndexSet indexSetWithIndexesInRange:{0, 1}]));
    AssertChanged(r2, @NO, @YES);
}

- (void)testOverwriteEmbeddedObjectViaAddParent {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r1(self, obj.object, RLMInvalidatedKey);
    KVORecorder r2(self, obj.array[0], RLMInvalidatedKey);

    [self.realm addOrUpdateObject:[[EmbeddedIntParentObject alloc] initWithValue:@[@1]]];
    AssertChanged(r1, @NO, @YES);
    AssertChanged(r2, @NO, @YES);
}

- (void)testOverwriteEmbeddedObjectViaCreateParent {
    EmbeddedIntParentObject *obj = [self createEmbeddedObject];
    KVORecorder r1(self, obj.object, RLMInvalidatedKey);
    KVORecorder r2(self, obj.array[0], RLMInvalidatedKey);

    [EmbeddedIntParentObject createOrUpdateInRealm:self.realm withValue:@[@1, NSNull.null, NSNull.null]];
    AssertChanged(r1, @NO, @YES);
    AssertChanged(r2, @NO, @YES);
}
@end

// Mutate a different accessor backed by the same row as the accessor being observed
@interface KVOMultipleAccessorsTests : KVOManagedObjectTests
@end
@implementation KVOMultipleAccessorsTests
- (id)observableForObject:(id)value {
    if (RLMObjectBase *obj = RLMDynamicCast<RLMObjectBase>(value)) {
        RLMObject *copy = RLMCreateManagedAccessor(RLMObjectBaseObjectSchema(obj).accessorClass, obj->_info);
        copy->_row = obj->_row;
        return copy;
    }
    else if (RLMArray *array = RLMDynamicCast<RLMArray>(value)) {
        return array;
    }
    else {
        XCTFail(@"unsupported type");
        return nil;
    }
}

- (void)testIgnoredProperty {
    // ignored properties do not notify other accessors for the same row
}

- (void)testAddOrUpdate {
    KVOObject *obj = [self createObject];
    KVOObject *obj2 = [[KVOObject alloc] initWithValue:obj];

    KVORecorder r(self, obj, @"boolCol");
    obj2.boolCol = true;
    XCTAssertTrue(r.empty());
    [self.realm addOrUpdateObject:obj2];
    AssertChanged(r, @NO, @YES);
}

- (void)testCreateOrUpdate {
    KVOObject *obj = [self createObject];
    KVOObject *obj2 = [[KVOObject alloc] initWithValue:obj];

    KVORecorder r(self, obj, @"boolCol");
    obj2.boolCol = true;
    XCTAssertTrue(r.empty());
    [KVOObject createOrUpdateInRealm:self.realm withValue:obj2];
    AssertChanged(r, @NO, @YES);
}

// The following tests aren't really multiple-accessor-specific, but they're
// conceptually similar and don't make sense in the multiple realm instances case
- (void)testCancelWriteTransactionWhileObservingNewObject {
    KVOObject *obj = [self createObject];
    KVORecorder r(self, obj, RLMInvalidatedKey);
    KVORecorder r2(self, obj, @"boolCol");
    [self.realm cancelWriteTransaction];
    AssertChanged(r, @NO, @YES);
    r2.pop_front();
    [self.realm beginWriteTransaction];
}

- (void)testCancelWriteTransactionWhileObservingChangedProperty {
    KVOObject *obj = [self createObject];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];

    obj.boolCol = YES;

    KVORecorder r(self, obj, @"boolCol");
    [self.realm cancelWriteTransaction];
    AssertChanged(r, @YES, @NO);

    [self.realm beginWriteTransaction];
}

- (void)testCancelWriteTransactionWhileObservingLinkToExistingObject {
    KVOObject *obj = [self createObject];
    KVOObject *obj2 = [self createObject];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];

    obj.objectCol = obj2;

    KVORecorder r(self, obj, @"objectCol");
    [self.realm cancelWriteTransaction];
    AssertChanged(r, obj2, NSNull.null);

    [self.realm beginWriteTransaction];
}

- (void)testCancelWriteTransactionWhileObservingLinkToNewObject {
    KVOObject *obj = [self createObject];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];

    obj.objectCol = [self createObject];

    KVORecorder r(self, obj, @"objectCol");
    [self.realm cancelWriteTransaction];

    if (NSDictionary *note = AssertNotification(r)) {
        XCTAssertTrue([note[NSKeyValueChangeOldKey] isKindOfClass:[RLMObjectBase class]]);
        XCTAssertEqualObjects(note[NSKeyValueChangeNewKey], NSNull.null);
    }

    [self.realm beginWriteTransaction];
}

- (void)testCancelWriteTransactionWhileObservingNewObjectLinkingToNewObject {
    KVOObject *obj = [self createObject];
    obj.objectCol = [self createObject];
    KVORecorder r(self, obj, RLMInvalidatedKey);
    KVORecorder r2(self, obj, @"objectCol");
    KVORecorder r3(self, obj, @"objectCol.boolCol");
    [self.realm cancelWriteTransaction];
    AssertChanged(r, @NO, @YES);
    [self.realm beginWriteTransaction];
}

- (void)testCancelWriteWithArrayChanges {
    KVOObject *obj = [self createObject];
    [obj.objectArray addObject:obj];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];

    {
        [obj.objectArray addObject:obj];
        KVORecorder r(self, obj, @"objectArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:1]);
    }
    {
        [obj.objectArray removeLastObject];
        KVORecorder r(self, obj, @"objectArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);
    }
    {
        obj.objectArray[0] = obj;
        KVORecorder r(self, obj, @"objectArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndex:0]);
    }

    // test batching with multiple items changed
    [obj.objectArray addObject:obj];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];
    {
        [obj.objectArray removeAllObjects];
        KVORecorder r(self, obj, @"objectArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, ([NSIndexSet indexSetWithIndexesInRange:{0, 2}]));
    }
    {
        [obj.objectArray removeLastObject];
        [obj.objectArray removeLastObject];
        KVORecorder r(self, obj, @"objectArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, ([NSIndexSet indexSetWithIndexesInRange:{0, 2}]));
    }
    {
        [obj.objectArray insertObject:obj atIndex:1];
        [obj.objectArray insertObject:obj atIndex:0];
        KVORecorder r(self, obj, @"objectArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        NSMutableIndexSet *expected = [NSMutableIndexSet new];
        [expected addIndex:0];
        [expected addIndex:2]; // shifted due to inserting at 0 after 1
        AssertIndexChange(NSKeyValueChangeRemoval, expected);
    }
    {
        [obj.objectArray insertObject:obj atIndex:0];
        [obj.objectArray removeLastObject];
        KVORecorder r(self, obj, @"objectArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertChanged(r, obj.objectArray, obj.objectArray);
    }
}

- (void)testCancelWriteWithPrimitiveArrayChanges {
    KVOObject *obj = [self createObject];
    [obj.intArray addObject:@1];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];

    {
        [obj.intArray addObject:@2];
        KVORecorder r(self, obj, @"intArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:1]);
    }
    {
        [obj.intArray removeLastObject];
        KVORecorder r(self, obj, @"intArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);
    }
    {
        obj.intArray[0] = @3;
        KVORecorder r(self, obj, @"intArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndex:0]);
    }

    // test batching with multiple items changed
    [obj.intArray addObject:@4];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];
    {
        [obj.intArray removeAllObjects];
        KVORecorder r(self, obj, @"intArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, ([NSIndexSet indexSetWithIndexesInRange:{0, 2}]));
    }
    {
        [obj.intArray removeLastObject];
        [obj.intArray removeLastObject];
        KVORecorder r(self, obj, @"intArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, ([NSIndexSet indexSetWithIndexesInRange:{0, 2}]));
    }
    {
        [obj.intArray insertObject:@5 atIndex:1];
        [obj.intArray insertObject:@6 atIndex:0];
        KVORecorder r(self, obj, @"intArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        NSMutableIndexSet *expected = [NSMutableIndexSet new];
        [expected addIndex:0];
        [expected addIndex:2]; // shifted due to inserting at 0 after 1
        AssertIndexChange(NSKeyValueChangeRemoval, expected);
    }
    {
        [obj.intArray insertObject:@7 atIndex:0];
        [obj.intArray removeLastObject];
        KVORecorder r(self, obj, @"intArray");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertChanged(r, obj.intArray, obj.intArray);
    }
}

- (void)testCancelWriteWithLinkedObjectedRemoved {
    KVOLinkObject2 *obj = [self createLinkObject];
    [obj.array addObject:obj.obj];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];

    {
        [self.realm deleteObject:obj.obj];

        KVORecorder r(self, obj, @"array");
        KVORecorder r2(self, obj, @"obj");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);
        AssertChanged(r2, NSNull.null, [KVOLinkObject1 allObjectsInRealm:self.realm].firstObject);
    }
    {
        [self.realm deleteObjects:[KVOLinkObject1 allObjectsInRealm:self.realm]];

        KVORecorder r(self, obj, @"array");
        KVORecorder r2(self, obj, @"obj");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);
        AssertChanged(r2, NSNull.null, [KVOLinkObject1 allObjectsInRealm:self.realm].firstObject);
    }
    {
        [self.realm deleteObjects:obj.array];

        KVORecorder r(self, obj, @"array");
        KVORecorder r2(self, obj, @"obj");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);
        AssertChanged(r2, NSNull.null, [KVOLinkObject1 allObjectsInRealm:self.realm].firstObject);
    }
}

- (void)testInvalidateRealm {
    KVOObject *obj = [self createObject];
    [self.realm commitWriteTransaction];

    KVORecorder r1(self, obj, RLMInvalidatedKey);
    KVORecorder r2(self, obj, @"objectArray.invalidated");
    [self.realm invalidate];
    [self.realm beginWriteTransaction];

    AssertChanged(r1, @NO, @YES);
    AssertChanged(r2, @NO, @YES);
}

- (void)testRenamedProperties {
    auto obj = [RenamedProperties1 createInRealm:self.realm withValue:@[@1, @"a"]];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];
    KVORecorder r(self, obj, @"propA");

    obj.propA = 2;
    AssertChanged(r, @1, @2);

    obj[@"propA"] = @3;
    AssertChanged(r, @2, @3);

    [obj setValue:@4 forKey:@"propA"];
    AssertChanged(r, @3, @4);

    // Only rollback will notify objects of different types with the same table,
    // not direct modification. Probably not worth fixing this.
    RenamedProperties2 *obj2 = [RenamedProperties2 allObjectsInRealm:self.realm].firstObject;
    KVORecorder r2(self, obj2, @"propC");

    [self.realm cancelWriteTransaction];
    [self.realm beginWriteTransaction];

    AssertChanged(r, @4, @1);
    AssertChanged(r2, @4, @1);
}
@end

// Observing an object from a different RLMRealm instance backed by the same
// row as the managed object being mutated
@interface KVOMultipleRealmsTests : KVOManagedObjectTests
@property RLMRealm *secondaryRealm;
@end

@implementation KVOMultipleRealmsTests
- (void)setUp {
    [super setUp];
    RLMRealmConfiguration *config = self.realm.configuration;
    config.cache = false;
    self.secondaryRealm = [RLMRealm realmWithConfiguration:config error:nil];
}

- (void)tearDown {
    self.secondaryRealm = nil;
    [super tearDown];
}

- (id)observableForObject:(id)value {
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];
    [self.secondaryRealm refresh];

    if (RLMObjectBase *obj = RLMDynamicCast<RLMObjectBase>(value)) {
        RLMObjectSchema *objectSchema = RLMObjectBaseObjectSchema(obj);
        RLMObject *copy = RLMCreateManagedAccessor(objectSchema.accessorClass,
                                                   &self.secondaryRealm->_info[objectSchema.className]);
        copy->_row = (*copy->_info->table()).get_object(obj->_row.get_key());
        return copy;
    }
    else if (RLMArray *array = RLMDynamicCast<RLMArray>(value)) {
        return array;
    }
    else {
        XCTFail(@"unsupported type");
        return nil;
    }

}

- (bool)collapsesNotifications {
    return true;
}

- (void)testIgnoredProperty {
    // ignored properties do not notify other accessors for the same row
}

- (void)testBatchArrayChanges {
    KVOObject *obj = [self createObject];
    [obj.objectArray addObject:obj];
    [obj.objectArray addObject:obj];
    [obj.objectArray addObject:obj];

    {
        KVORecorder r(self, obj, @"objectArray");
        [obj.objectArray insertObject:obj atIndex:1];
        [obj.objectArray insertObject:obj atIndex:0];

        NSMutableIndexSet *expected = [NSMutableIndexSet new];
        [expected addIndex:0];
        [expected addIndex:2]; // shifted due to inserting at 0 after 1
        AssertIndexChange(NSKeyValueChangeInsertion, expected);
    }

    {
        KVORecorder r(self, obj, @"objectArray");
        [obj.objectArray removeObjectAtIndex:3];
        [obj.objectArray removeObjectAtIndex:3];
        AssertIndexChange(NSKeyValueChangeRemoval, ([NSIndexSet indexSetWithIndexesInRange:{3, 2}]));
    }

    {
        KVORecorder r(self, obj, @"objectArray");
        [obj.objectArray removeObjectAtIndex:0];
        [obj.objectArray removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, ([NSIndexSet indexSetWithIndexesInRange:{0, 3}]));
    }

    [obj.objectArray addObject:obj];
    {
        KVORecorder r(self, obj, @"objectArray");
        [obj.objectArray addObject:obj];
        [obj.objectArray removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:0]);
    }

    [obj.objectArray addObject:obj];
    {
        KVORecorder r(self, obj, @"objectArray");
        obj.objectArray[0] = obj;
        [obj.objectArray removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:0]);
    }
}

- (void)testOrderedErase {
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:10];
    for (int i = 0; i < 10; ++i) @autoreleasepool {
        [objects addObject:[ObjectWithNoLinksToOrFrom createInRealm:self.realm withValue:@[@(i)]]];
    }

    // deleteObject: always uses move_last_over(), but TableView::clear() uses
    // erase() if there's no links
    auto deleteObject = ^(int value) {
        [self.realm deleteObjects:[ObjectWithNoLinksToOrFrom objectsInRealm:self.realm where:@"value = %d", value]];
    };

    { // delete object before observed, then observed
        KVORecorder r(self, objects[2], @"invalidated");
        deleteObject(1);
        deleteObject(2);
        AssertChanged(r, @NO, @YES);
    }

    { // delete object after observed, then observed
        KVORecorder r(self, objects[3], @"invalidated");
        deleteObject(4);
        deleteObject(3);
        AssertChanged(r, @NO, @YES);
    }

    { // delete observed, then object before observed
        KVORecorder r(self, objects[6], @"invalidated");
        deleteObject(6);
        deleteObject(5);
        AssertChanged(r, @NO, @YES);
    }

    { // delete observed, then object after observed
        KVORecorder r(self, objects[7], @"invalidated");
        deleteObject(7);
        deleteObject(8);
        AssertChanged(r, @NO, @YES);
    }
}
@end

// Test with the table column order not matching the order of the properties
@interface KVOManagedObjectWithReorderedPropertiesTests : KVOManagedObjectTests
@end

@implementation KVOManagedObjectWithReorderedPropertiesTests
- (RLMRealm *)getRealm {
    // Initialize the file with the properties in reverse order, then re-open
    // with it in the normal order while the reversed one is still open (as
    // otherwise it'll recreate the file due to being in-memory)
    RLMSchema *schema = [RLMSchema new];
    schema.objectSchema = @[[self reverseProperties:KVOObject.sharedSchema],
                            [self reverseProperties:KVOLinkObject1.sharedSchema],
                            [self reverseProperties:KVOLinkObject2.sharedSchema]];

    RLMRealmConfiguration *configuration = [[RLMRealmConfiguration alloc] init];
    configuration.cache = false;
    configuration.inMemoryIdentifier = @"test";
    configuration.customSchema = schema;
    RLMRealm *reversedRealm = [RLMRealm realmWithConfiguration:configuration error:nil];

    configuration.customSchema = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
    XCTAssertNotEqualObjects(realm.schema, reversedRealm.schema);
    return realm;
}

- (RLMObjectSchema *)reverseProperties:(RLMObjectSchema *)source {
    RLMObjectSchema *objectSchema = [source copy];
    objectSchema.properties = objectSchema.properties.reverseObjectEnumerator.allObjects;
    return objectSchema;
}
@end
