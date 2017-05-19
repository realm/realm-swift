////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import "RLMResults_Private.h"

#import "RLMAccessor.hpp"
#import "RLMArray_Private.hpp"
#import "RLMCollection_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMThreadSafeReference_Private.hpp"
#import "RLMUtil.hpp"

#import "results.hpp"

#import <objc/runtime.h>
#import <objc/message.h>
#import <realm/table_view.hpp>

using namespace realm;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation RLMNotificationToken
@end
#pragma clang diagnostic pop

@interface RLMResults () <RLMThreadConfined_Private>
@end

//
// RLMResults implementation
//
@implementation RLMResults {
    realm::Results _results;
    RLMRealm *_realm;
    RLMClassInfo *_info;
}

- (instancetype)initPrivate {
    self = [super init];
    return self;
}

static void assertKeyPathIsNotNested(NSString *keyPath) {
    if ([keyPath rangeOfString:@"."].location != NSNotFound) {
        @throw RLMException(@"Nested key paths are not supported yet for KVC collection operators.");
    }
}

[[gnu::noinline]]
[[noreturn]]
static void throwError(NSString *aggregateMethod) {
    try {
        throw;
    }
    catch (realm::InvalidTransactionException const&) {
        @throw RLMException(@"Cannot modify Results outside of a write transaction");
    }
    catch (realm::IncorrectThreadException const&) {
        @throw RLMException(@"Realm accessed from incorrect thread");
    }
    catch (realm::Results::InvalidatedException const&) {
        @throw RLMException(@"RLMResults has been invalidated");
    }
    catch (realm::Results::DetatchedAccessorException const&) {
        @throw RLMException(@"Object has been invalidated");
    }
    catch (realm::Results::IncorrectTableException const& e) {
        @throw RLMException(@"Object type '%s' does not match RLMResults type '%s'.",
                            e.actual.data(), e.expected.data());
    }
    catch (realm::Results::OutOfBoundsIndexException const& e) {
        @throw RLMException(@"Index %zu is out of bounds (must be less than %zu)",
                            e.requested, e.valid_count);
    }
    catch (realm::Results::UnsupportedColumnTypeException const& e) {
        @throw RLMException(@"%@ is not supported for %@ property '%s'",
                            aggregateMethod,
                            RLMTypeToString((RLMPropertyType)e.column_type),
                            e.column_name.data());
    }
}

template<typename Function>
static auto translateErrors(Function&& f, NSString *aggregateMethod=nil) {
    try {
        return f();
    }
    catch (...) {
        throwError(aggregateMethod);
    }
}

+ (instancetype)resultsWithObjectInfo:(RLMClassInfo&)info
                              results:(realm::Results)results {
    RLMResults *ar = [[self alloc] initPrivate];
    ar->_results = std::move(results);
    ar->_realm = info.realm;
    ar->_info = &info;
    return ar;
}

+ (instancetype)emptyDetachedResults {
    return [[self alloc] initPrivate];
}

static inline void RLMResultsValidateInWriteTransaction(__unsafe_unretained RLMResults *const ar) {
    ar->_realm->_realm->verify_thread();
    ar->_realm->_realm->verify_in_write();
}

- (BOOL)isInvalidated {
    return translateErrors([&] { return !_results.is_valid(); });
}

- (NSUInteger)count {
    return translateErrors([&] { return _results.size(); });
}

- (NSString *)objectClassName {
    return RLMStringDataToNSString(_results.get_object_type());
}

- (RLMClassInfo *)objectInfo {
    return _info;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    if (!_info) {
        return 0;
    }

    __autoreleasing RLMFastEnumerator *enumerator;
    if (state->state == 0) {
        enumerator = [[RLMFastEnumerator alloc] initWithCollection:self objectSchema:*_info];
        state->extra[0] = (long)enumerator;
        state->extra[1] = self.count;
    }
    else {
        enumerator = (__bridge id)(void *)state->extra[0];
    }

    return [enumerator countByEnumeratingWithState:state count:len];
}

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    NSUInteger index = [self indexOfObjectWhere:predicateFormat args:args];
    va_end(args);
    return index;
}

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args {
    return [self indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:predicateFormat
                                                                   arguments:args]];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    if (_results.get_mode() == Results::Mode::Empty) {
        return NSNotFound;
    }

    return translateErrors([&] {
        return RLMConvertNotFound(_results.index_of(RLMPredicateToQuery(predicate, _info->rlmObjectSchema, _realm.schema, _realm.group)));
    });
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMAccessorContext ctx(_realm, *_info);
    return translateErrors([&] {
        return _results.get(ctx, index);
    });
}

- (id)firstObject {
    if (!_info) {
        return nil;
    }
    RLMAccessorContext ctx(_realm, *_info);
    return translateErrors([&] {
        return _results.first(ctx);
    });
}

- (id)lastObject {
    if (!_info) {
        return nil;
    }
    RLMAccessorContext ctx(_realm, *_info);
    return translateErrors([&] {
        return _results.last(ctx);
    });
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    if (!_info || !object || (!object->_realm && !object.invalidated)) {
        return NSNotFound;
    }
    RLMAccessorContext ctx(_realm, *_info);
    return translateErrors([&] {
        return RLMConvertNotFound(_results.index_of(ctx, object));
    });
}

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath characterAtIndex:0] == '@') {
        if ([keyPath isEqualToString:@"@count"]) {
            return @(self.count);
        }
        NSRange operatorRange = [keyPath rangeOfString:@"." options:NSLiteralSearch];
        NSUInteger keyPathLength = keyPath.length;
        NSUInteger separatorIndex = operatorRange.location != NSNotFound ? operatorRange.location : keyPathLength;
        NSString *operatorName = [keyPath substringWithRange:NSMakeRange(1, separatorIndex - 1)];
        SEL opSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@ForKeyPath:", operatorName]);
        BOOL isValidOperator = [self respondsToSelector:opSelector];
        if (!isValidOperator) {
            @throw RLMException(@"Unsupported KVC collection operator found in key path '%@'", keyPath);
        }
        else if (separatorIndex >= keyPathLength - 1) {
            @throw RLMException(@"Missing key path for KVC collection operator %@ in key path '%@'", operatorName, keyPath);
        }
        NSString *operatorKeyPath = [keyPath substringFromIndex:separatorIndex + 1];
        if (isValidOperator) {
            return ((id(*)(id, SEL, id))objc_msgSend)(self, opSelector, operatorKeyPath);
        }
    }
    return [super valueForKeyPath:keyPath];
}

- (id)valueForKey:(NSString *)key {
    return translateErrors([&] {
        return RLMCollectionValueForKey(self, key);
    });
}

- (void)setValue:(id)value forKey:(NSString *)key {
    translateErrors([&] { RLMResultsValidateInWriteTransaction(self); });
    RLMCollectionSetValueForKey(self, key, value);
}

- (NSNumber *)_aggregateForKeyPath:(NSString *)keyPath method:(util::Optional<Mixed> (Results::*)(size_t))method
                        methodName:(NSString *)methodName returnNilForEmpty:(BOOL)returnNilForEmpty {
    assertKeyPathIsNotNested(keyPath);
    return [self aggregate:keyPath method:method methodName:methodName returnNilForEmpty:returnNilForEmpty];
}

- (NSNumber *)_minForKeyPath:(NSString *)keyPath {
    return [self _aggregateForKeyPath:keyPath method:&Results::min methodName:@"@min" returnNilForEmpty:YES];
}

- (NSNumber *)_maxForKeyPath:(NSString *)keyPath {
    return [self _aggregateForKeyPath:keyPath method:&Results::max methodName:@"@max" returnNilForEmpty:YES];
}

- (NSNumber *)_sumForKeyPath:(NSString *)keyPath {
    return [self _aggregateForKeyPath:keyPath method:&Results::sum methodName:@"@sum" returnNilForEmpty:NO];
}

- (NSNumber *)_avgForKeyPath:(NSString *)keyPath {
    return [self _aggregateForKeyPath:keyPath method:&Results::average methodName:@"@avg" returnNilForEmpty:YES];
}

- (NSArray *)_unionOfObjectsForKeyPath:(NSString *)keyPath {
    assertKeyPathIsNotNested(keyPath);
    return translateErrors([&] {
        return RLMCollectionValueForKey(self, keyPath);
    });
}

- (NSArray *)_distinctUnionOfObjectsForKeyPath:(NSString *)keyPath {
    return [NSSet setWithArray:[self _unionOfObjectsForKeyPath:keyPath]].allObjects;
}

- (NSArray *)_unionOfArraysForKeyPath:(NSString *)keyPath {
    assertKeyPathIsNotNested(keyPath);
    if ([keyPath isEqualToString:@"self"]) {
        @throw RLMException(@"self is not a valid key-path for a KVC array collection operator as 'unionOfArrays'.");
    }

    return translateErrors([&] {
        NSArray *nestedResults = RLMCollectionValueForKey(self, keyPath);
        NSMutableArray *flatArray = [NSMutableArray arrayWithCapacity:nestedResults.count];
        for (id<RLMFastEnumerable> array in nestedResults) {
            NSArray *nsArray = RLMCollectionValueForKey(array, @"self");
            [flatArray addObjectsFromArray:nsArray];
        }
        return flatArray;
    });
}

- (NSArray *)_distinctUnionOfArraysForKeyPath:(__unused NSString *)keyPath {
    return [NSSet setWithArray:[self _unionOfArraysForKeyPath:keyPath]].allObjects;
}

- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    RLMResults *results = [self objectsWhere:predicateFormat args:args];
    va_end(args);
    return results;
}

- (RLMResults *)objectsWhere:(NSString *)predicateFormat args:(va_list)args {
    return [self objectsWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    return translateErrors([&] {
        if (_results.get_mode() == Results::Mode::Empty) {
            return self;
        }
        auto query = RLMPredicateToQuery(predicate, _info->rlmObjectSchema, _realm.schema, _realm.group);
        return [RLMResults resultsWithObjectInfo:*_info results:_results.filter(std::move(query))];
    });
}

- (RLMResults *)sortedResultsUsingKeyPath:(NSString *)keyPath ascending:(BOOL)ascending {
    return [self sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithKeyPath:keyPath ascending:ascending]]];
}

- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending {
    return [self sortedResultsUsingKeyPath:property ascending:ascending];
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties {
    if (properties.count == 0) {
        return self;
    }
    return translateErrors([&] {
        if (_results.get_mode() == Results::Mode::Empty) {
            return self;
        }

        return [RLMResults resultsWithObjectInfo:*_info results:_results.sort(RLMSortDescriptorFromDescriptors(*_info, properties))];
    });
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (id)aggregate:(NSString *)property method:(util::Optional<Mixed> (Results::*)(size_t))method
     methodName:(NSString *)methodName returnNilForEmpty:(BOOL)returnNilForEmpty {
    if (_results.get_mode() == Results::Mode::Empty) {
        return returnNilForEmpty ? nil : @0;
    }
    size_t column = _info->tableColumn(property);
    auto value = translateErrors([&] { return (_results.*method)(column); }, methodName);
    if (!value) {
        return nil;
    }
    return RLMMixedToObjc(*value);
}

- (id)minOfProperty:(NSString *)property {
    return [self aggregate:property method:&Results::min methodName:@"minOfProperty" returnNilForEmpty:YES];
}

- (id)maxOfProperty:(NSString *)property {
    return [self aggregate:property method:&Results::max methodName:@"maxOfProperty" returnNilForEmpty:YES];
}

- (id)sumOfProperty:(NSString *)property {
    return [self aggregate:property method:&Results::sum methodName:@"sumOfProperty" returnNilForEmpty:NO];
}

- (id)averageOfProperty:(NSString *)property {
    return [self aggregate:property method:&Results::average methodName:@"averageOfProperty" returnNilForEmpty:YES];
}

- (void)deleteObjectsFromRealm {
    return translateErrors([&] {
        if (_results.get_mode() == Results::Mode::Table) {
            RLMResultsValidateInWriteTransaction(self);
            RLMClearTable(*_info);
        }
        else {
            RLMTrackDeletions(_realm, [&] { _results.clear(); });
        }
    });
}

- (NSString *)description {
    return RLMDescriptionWithMaxDepth(@"RLMResults", self, RLMDescriptionMaxDepth);
}

- (NSUInteger)indexInSource:(NSUInteger)index {
    return translateErrors([&] { return _results.get(index).get_index(); });
}

- (realm::TableView)tableView {
    return translateErrors([&] { return _results.get_tableview(); });
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMCollectionChange *, NSError *))block {
    [_realm verifyNotificationsAreSupported];
    return RLMAddNotificationBlock(self, _results, block, true);
}
#pragma clang diagnostic pop

- (BOOL)isAttached
{
    return !!_realm;
}

#pragma mark - Thread Confined Protocol Conformance

- (std::unique_ptr<realm::ThreadSafeReferenceBase>)makeThreadSafeReference {
    return std::make_unique<realm::ThreadSafeReference<Results>>(_realm->_realm->obtain_thread_safe_reference(_results));
}

- (id)objectiveCMetadata {
    return nil;
}

+ (instancetype)objectWithThreadSafeReference:(std::unique_ptr<realm::ThreadSafeReferenceBase>)reference
                                     metadata:(__unused id)metadata
                                        realm:(RLMRealm *)realm {
    REALM_ASSERT_DEBUG(dynamic_cast<realm::ThreadSafeReference<Results> *>(reference.get()));
    auto results_reference = static_cast<realm::ThreadSafeReference<Results> *>(reference.get());

    Results results = realm->_realm->resolve_thread_safe_reference(std::move(*results_reference));

    return [RLMResults resultsWithObjectInfo:realm->_info[RLMStringDataToNSString(results.get_object_type())]
                                     results:std::move(results)];
}

@end

@implementation RLMLinkingObjects
@end
