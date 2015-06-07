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
#import "RLMPredicateUtil.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"

#import <atomic>
#import <memory>
#import <vector>

RLM_ARRAY_TYPE(KVOObject)
RLM_ARRAY_TYPE(KVOLinkObject1)

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
@property KVOObject           *objectCol;
@property RLMArray<KVOObject> *arrayCol;
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
@property NSMutableArray *arrayCol;
@end
@implementation PlainKVOObject
@end

@interface PlainLinkObject1 : NSObject
@property PlainKVOObject *obj;
@property NSMutableArray *array;
@end
@implementation PlainLinkObject1
@end

@interface PlainLinkObject2 : NSObject
@property PlainLinkObject1 *obj;
@property NSMutableArray *array;
@end
@implementation PlainLinkObject2
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
        id self = _observer;
        @try {
            [_obj removeObserver:_observer forKeyPath:_keyPath context:this];
        }
        @catch (NSException *e) {
            XCTFail(@"%@", e.description);
        }
//        assert(_notifications.count == 0);
        XCTAssertEqual(0U, _notifications.count);
    }

    // record a single notification
    void operator()(NSString *key, id obj, NSDictionary *changeDictionary) {
        id self = _observer;
        XCTAssertEqual(obj, _obj);
        XCTAssertEqualObjects(key, _keyPath);
        [_notifications addObject:changeDictionary.copy];
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
    obj.arrayCol = [NSMutableArray array];
    return obj;
}

- (id)createLinkObject {
    PlainLinkObject1 *obj1 = [PlainLinkObject1 new];
    obj1.obj = [self createObject];
    obj1.array = [NSMutableArray new];

    PlainLinkObject2 *obj2 = [PlainLinkObject2 new];
    obj2.obj = obj1;
    obj2.array = [NSMutableArray new];

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
    }

    {
        KVORecorder r(self, obj, @"binaryCol");
        NSData *data = [@"abc" dataUsingEncoding:NSUTF8StringEncoding];
        obj.binaryCol = data;
        AssertChanged(r, NSData.data, data);
    }

    {
        KVORecorder r(self, obj, @"dateCol");
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:1];
        obj.dateCol = date;
        AssertChanged(r, [NSDate dateWithTimeIntervalSinceReferenceDate:0], date);
    }

    {
        KVORecorder r(self, obj, @"objectCol");
        obj.objectCol = obj;
        AssertChanged(r, NSNull.null, [self observableForObject:obj]);
    }

    { // should be testing assignment, not mutation
        KVORecorder r(self, obj, @"arrayCol");
        id mutator = [obj mutableArrayValueForKey:@"arrayCol"];
        [mutator addObject:obj];
        r.refresh();
        r.pop_front();
    }
}

- (void)testArrayDiffs {
    KVOObject *obj = [self createObject];
    KVORecorder r(self, obj, @"arrayCol");

    id mutator = [obj mutableArrayValueForKey:@"arrayCol"];

#define AssertIndexChange(kind, indexes) do { \
    if (NSDictionary *note = AssertNotification(r)) { \
        XCTAssertEqual([note[NSKeyValueChangeKindKey] intValue], kind); \
        XCTAssertEqualObjects(note[NSKeyValueChangeIndexesKey], indexes); \
    } \
    XCTAssertTrue(r.empty()); \
} while (0)

    [mutator addObject:obj];
    AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);

    [mutator addObject:obj];
    AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:1]);

    [mutator removeObjectAtIndex:0];
    AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:0]);

    [mutator replaceObjectAtIndex:0 withObject:obj];
    AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndex:0]);

    NSMutableIndexSet *indexes = [NSMutableIndexSet new];
    [indexes addIndex:0];
    [indexes addIndex:2];
    [mutator insertObjects:@[obj, obj] atIndexes:indexes];
    AssertIndexChange(NSKeyValueChangeInsertion, indexes);

    [mutator removeObjectsAtIndexes:indexes];
    AssertIndexChange(NSKeyValueChangeRemoval, indexes);

    // We deliberately diverge from NSMutableArray for `removeAllObjects` and
    // `addObjectsFromArray:`, because generating a separate notification for
    // each object added or removed is needlessly pessimal.
    if (![obj.arrayCol isKindOfClass:[NSArray class]]) {
        [mutator addObjectsFromArray:@[obj, obj]];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]);

        [mutator removeLastObject];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:2]);

        [mutator removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);
    }
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

// RLMArray doesn't support @count at all
//- (void)testObserveArrayCount {
//    KVOObject *obj = [self createObject];
//    KVORecorder r(self, obj, @"arrayCol.@count");
//    id mutator = [obj mutableArrayValueForKey:@"arrayCol"];
//    [mutator addObject:obj];
//    AssertChanged(r, @0, @1);
//}
@end

// Run tests on a standalone RLMObject instance
@interface KVOStandaloneObjectTests : KVOTests
@end
@implementation KVOStandaloneObjectTests
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

@end

// Run tests on a persisted object, modifying the actual object instance being
// observed
@interface KVOPersistedObjectTests : KVOTests
@property (nonatomic, strong) RLMRealm *realm;
@end

@implementation KVOPersistedObjectTests
- (void)setUp {
    [super setUp];
    _realm = RLMRealm.defaultRealm;
    [_realm beginWriteTransaction];
}

- (void)tearDown {
    [self.realm cancelWriteTransaction];
    self.realm = nil;
    [super tearDown];
}

- (id)createObject {
    static std::atomic<int> pk{0};
    return [KVOObject createInDefaultRealmWithValue:@[@(++pk),
                                                       @NO, @1, @2, @3, @0, @0, @NO, @"",
                                                       NSData.data, [NSDate dateWithTimeIntervalSinceReferenceDate:0],
                                                       NSNull.null, NSNull.null]];
}

- (id)createLinkObject {
    static std::atomic<int> pk{0};
    return [KVOLinkObject2 createInDefaultRealmWithValue:@[@(++pk), @[@(++pk), [self createObject], @[]], @[]]];
}

- (void)testDeleteObservedObject {
    KVOObject *obj = [self createObject];
    KVORecorder r1(self, obj, @"boolCol");
    KVORecorder r2(self, obj, RLMInvalidatedKey);
    [self.realm deleteObject:obj];
    AssertChanged(r2, @NO, @YES);
    // should not crash
}

- (void)testDeleteMiddleOfKeyPath {
    KVOLinkObject2 *obj = [self createLinkObject];
    KVORecorder r(self, obj, @"obj.obj.boolCol");
    [self.realm deleteObject:obj.obj];
    AssertChanged(r, @NO, NSNull.null);
}

- (void)testDeleteParentOfObservedRLMArray {
    KVOObject *obj = [self createObject];
    KVORecorder r1(self, obj, @"arrayCol");
    KVORecorder r2(self, obj, @"arrayCol.invalidated");
    KVORecorder r3(self, obj.arrayCol, RLMInvalidatedKey);
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
    // TODO
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

@end

// Mutate a different accessor backed by the same row as the accessor being observed
@interface KVOMultipleAccessorsTests : KVOPersistedObjectTests
@end
@implementation KVOMultipleAccessorsTests
- (id)observableForObject:(id)value {
    if (RLMObject *obj = RLMDynamicCast<RLMObject>(value)) {
        RLMObject *copy = [[obj.objectSchema.accessorClass alloc] initWithRealm:obj.realm schema:obj.objectSchema];
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
    [obj.arrayCol addObject:obj];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];

    {
        [obj.arrayCol addObject:obj];
        KVORecorder r(self, obj, @"arrayCol");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:1]);
    }
    {
        [obj.arrayCol removeLastObject];
        KVORecorder r(self, obj, @"arrayCol");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, [NSIndexSet indexSetWithIndex:0]);
    }
    {
        obj.arrayCol[0] = obj;
        KVORecorder r(self, obj, @"arrayCol");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeReplacement, [NSIndexSet indexSetWithIndex:0]);
    }

    // test batching with multiple items changed
    [obj.arrayCol addObject:obj];
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];
    {
        [obj.arrayCol removeAllObjects];
        KVORecorder r(self, obj, @"arrayCol");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, ([NSIndexSet indexSetWithIndexesInRange:{0, 2}]));
    }
    {
        [obj.arrayCol removeLastObject];
        [obj.arrayCol removeLastObject];
        KVORecorder r(self, obj, @"arrayCol");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertIndexChange(NSKeyValueChangeInsertion, ([NSIndexSet indexSetWithIndexesInRange:{0, 2}]));
    }
    {
        [obj.arrayCol insertObject:obj atIndex:1];
        [obj.arrayCol insertObject:obj atIndex:0];
        KVORecorder r(self, obj, @"arrayCol");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        NSMutableIndexSet *expected = [NSMutableIndexSet new];
        [expected addIndex:0];
        [expected addIndex:2]; // shifted due to inserting at 0 after 1
        AssertIndexChange(NSKeyValueChangeRemoval, expected);
    }
    {
        [obj.arrayCol insertObject:obj atIndex:0];
        [obj.arrayCol removeLastObject];
        KVORecorder r(self, obj, @"arrayCol");
        [self.realm cancelWriteTransaction];
        [self.realm beginWriteTransaction];
        AssertChanged(r, obj.arrayCol, obj.arrayCol);
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

// linkview and table selection ordering
@end

// Observing an object from a different RLMRealm instance backed by the same
// row as the persisted object being mutated
@interface KVOMultipleRealmsTests : KVOPersistedObjectTests
@property RLMRealm *secondaryRealm;
@end

@implementation KVOMultipleRealmsTests
- (void)setUp {
    [super setUp];
    // use private constructor to bypass cache and get a second instance on the
    // same thread
    self.secondaryRealm = [[RLMRealm alloc] initWithPath:self.realm.path
                                                     key:nil readOnly:NO
                                                inMemory:NO dynamic:NO error:nil];
    RLMRealmSetSchema(self.secondaryRealm, [self.realm.schema shallowCopy], false);
}

- (void)tearDown {
    self.secondaryRealm = nil;
    [super tearDown];
}

- (id)observableForObject:(id)value {
    [self.realm commitWriteTransaction];
    [self.realm beginWriteTransaction];
    [self.secondaryRealm refresh];

    if (RLMObject *obj = RLMDynamicCast<RLMObject>(value)) {
        RLMObject *copy = [[obj.objectSchema.accessorClass alloc] initWithRealm:self.secondaryRealm
                                                                         schema:self.secondaryRealm.schema[obj.objectSchema.className]];
        copy->_row = (*copy.objectSchema.table)[obj->_row.get_index()];
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
    [obj.arrayCol addObject:obj];
    [obj.arrayCol addObject:obj];
    [obj.arrayCol addObject:obj];

    {
        KVORecorder r(self, obj, @"arrayCol");
        [obj.arrayCol insertObject:obj atIndex:1];
        [obj.arrayCol insertObject:obj atIndex:0];

        NSMutableIndexSet *expected = [NSMutableIndexSet new];
        [expected addIndex:0];
        [expected addIndex:2]; // shifted due to inserting at 0 after 1
        AssertIndexChange(NSKeyValueChangeInsertion, expected);
    }

    {
        KVORecorder r(self, obj, @"arrayCol");
        [obj.arrayCol removeObjectAtIndex:3];
        [obj.arrayCol removeObjectAtIndex:3];
        AssertIndexChange(NSKeyValueChangeRemoval, ([NSIndexSet indexSetWithIndexesInRange:{3, 2}]));
    }

    {
        KVORecorder r(self, obj, @"arrayCol");
        [obj.arrayCol removeObjectAtIndex:0];
        [obj.arrayCol removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, ([NSIndexSet indexSetWithIndexesInRange:{0, 3}]));
    }

    [obj.arrayCol addObject:obj];
    {
        KVORecorder r(self, obj, @"arrayCol");
        [obj.arrayCol addObject:obj];
        [obj.arrayCol removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:0]);
    }

    [obj.arrayCol addObject:obj];
    {
        KVORecorder r(self, obj, @"arrayCol");
        obj.arrayCol[0] = obj;
        [obj.arrayCol removeAllObjects];
        AssertIndexChange(NSKeyValueChangeRemoval, [NSIndexSet indexSetWithIndex:0]);
    }
}
@end

