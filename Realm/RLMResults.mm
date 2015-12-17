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

#import "RLMArray_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

#import "results.hpp"

#import <objc/runtime.h>
#import <objc/message.h>
#import <realm/table_view.hpp>

using namespace realm;

static const int RLMEnumerationBufferSize = 16;

@implementation RLMFastEnumerator {
    // The buffer supplied by fast enumeration does not retain the objects given
    // to it, but because we create objects on-demand and don't want them
    // autoreleased (a table can have more rows than the device has memory for
    // accessor objects) we need a thing to retain them.
    id _strongBuffer[RLMEnumerationBufferSize];

    RLMRealm *_realm;
    RLMObjectSchema *_objectSchema;

    // Collection being enumerated. Only one of these two will be valid: when
    // possible we enumerate the collection directly, but when in a write
    // transaction we instead create a frozen TableView and enumerate that
    // instead so that mutating the collection during enumeration works.
    id<RLMFastEnumerable> _collection;
    realm::TableView _tableView;
}

- (instancetype)initWithCollection:(id<RLMFastEnumerable>)collection objectSchema:(RLMObjectSchema *)objectSchema {
    self = [super init];
    if (self) {
        _realm = collection.realm;
        _objectSchema = objectSchema;

        if (_realm.inWriteTransaction) {
            _tableView = [collection tableView];
        }
        else {
            _collection = collection;
            [_realm registerEnumerator:self];
        }
    }
    return self;
}

- (void)dealloc {
    if (_collection) {
        [_realm unregisterEnumerator:self];
    }
}

- (void)detach {
    _tableView = [_collection tableView];
    _collection = nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len {
    [_realm verifyThread];
    if (!_tableView.is_attached() && !_collection) {
        @throw RLMException(@"Collection is no longer valid");
    }
    // The fast enumeration buffer size is currently a hardcoded number in the
    // compiler so this can't actually happen, but just in case it changes in
    // the future...
    if (len > RLMEnumerationBufferSize) {
        len = RLMEnumerationBufferSize;
    }

    NSUInteger batchCount = 0, count = state->extra[1];

    Class accessorClass = _objectSchema.accessorClass;
    for (NSUInteger index = state->state; index < count && batchCount < len; ++index) {
        RLMObject *accessor = [[accessorClass alloc] initWithRealm:_realm schema:_objectSchema];
        if (_collection) {
            accessor->_row = (*_objectSchema.table)[[_collection indexInSource:index]];
        }
        else if (_tableView.is_row_attached(index)) {
            accessor->_row = (*_objectSchema.table)[_tableView.get_source_ndx(index)];
        }
        _strongBuffer[batchCount] = accessor;
        batchCount++;
    }

    for (NSUInteger i = batchCount; i < len; ++i) {
        _strongBuffer[i] = nil;
    }

    if (batchCount == 0) {
        // Release our data if we're done, as we're autoreleased and so may
        // stick around for a while
        _collection = nil;
        if (_tableView.is_attached()) {
            _tableView = TableView();
        }
        else {
            [_realm unregisterEnumerator:self];
        }
    }

    state->itemsPtr = (__unsafe_unretained id *)(void *)_strongBuffer;
    state->state += batchCount;
    state->mutationsPtr = state->extra+1;

    return batchCount;
}
@end

//
// RLMResults implementation
//
@implementation RLMResults {
    realm::Results _results;
    RLMRealm *_realm;
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

+ (instancetype)resultsWithObjectSchema:(RLMObjectSchema *)objectSchema
                                results:(realm::Results)results {
    RLMResults *ar = [[self alloc] initPrivate];
    ar->_results = std::move(results);
    ar->_realm = objectSchema.realm;
    ar->_objectSchema = objectSchema;
    return ar;
}

static inline void RLMResultsValidateInWriteTransaction(__unsafe_unretained RLMResults *const ar) {
    ar->_realm->_realm->verify_thread();
    ar->_realm->_realm->verify_in_write();
}

- (NSUInteger)count {
    return translateErrors([&] { return _results.size(); });
}

- (NSString *)objectClassName {
    return RLMStringDataToNSString(_results.get_object_type());
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    __autoreleasing RLMFastEnumerator *enumerator;
    if (state->state == 0) {
        enumerator = [[RLMFastEnumerator alloc] initWithCollection:self objectSchema:_objectSchema];
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

    Query query = translateErrors([&] { return _results.get_query(); });
    RLMUpdateQueryWithPredicate(&query, predicate, _realm.schema, _objectSchema);
    size_t index = query.find();
    if (index == realm::not_found) {
        return NSNotFound;
    }
    return _results.index_of(index);
}

- (id)objectAtIndex:(NSUInteger)index {
    return translateErrors([&] {
        return RLMCreateObjectAccessor(_realm, _objectSchema, _results.get(index));
    });
}

- (id)firstObject {
    auto row = translateErrors([&] { return _results.first(); });
    return row ? RLMCreateObjectAccessor(_realm, _objectSchema, *row) : nil;
}

- (id)lastObject {
    auto row = translateErrors([&] { return _results.last(); });
    return row ? RLMCreateObjectAccessor(_realm, _objectSchema, *row) : nil;
}

- (NSUInteger)indexOfObject:(RLMObject *)object {
    if (!object || (!object->_realm && !object.invalidated)) {
        return NSNotFound;
    }

    return translateErrors([&] {
        return RLMConvertNotFound(_results.index_of(object->_row));
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

- (NSNumber *)_aggregateForKeyPath:(NSString *)keyPath method:(util::Optional<Mixed> (Results::*)(size_t))method methodName:(NSString *)methodName {
    assertKeyPathIsNotNested(keyPath);
    return [self aggregate:keyPath method:method methodName:methodName];
}

- (NSNumber *)_minForKeyPath:(NSString *)keyPath {
    return [self _aggregateForKeyPath:keyPath method:&Results::min methodName:@"@min"];
}

- (NSNumber *)_maxForKeyPath:(NSString *)keyPath {
    return [self _aggregateForKeyPath:keyPath method:&Results::max methodName:@"@max"];
}

- (NSNumber *)_sumForKeyPath:(NSString *)keyPath {
    return [self _aggregateForKeyPath:keyPath method:&Results::sum methodName:@"@sum"];
}

- (NSNumber *)_avgForKeyPath:(NSString *)keyPath {
    return [self _aggregateForKeyPath:keyPath method:&Results::average methodName:@"@avg"];
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
        auto query = _results.get_query();
        RLMUpdateQueryWithPredicate(&query, predicate, _realm.schema, _objectSchema);
        return [RLMResults resultsWithObjectSchema:_objectSchema
                                           results:realm::Results(_realm->_realm, std::move(query), _results.get_sort())];
    });
}

- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending {
    return [self sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:property ascending:ascending]]];
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties {
    return translateErrors([&] {
        if (_results.get_mode() == Results::Mode::Empty) {
            return self;
        }

        return [RLMResults resultsWithObjectSchema:_objectSchema
                                           results:_results.sort(RLMSortOrderFromDescriptors(_objectSchema, properties))];
    });
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (id)aggregate:(NSString *)property method:(util::Optional<Mixed> (Results::*)(size_t))method methodName:(NSString *)methodName {
    size_t column = RLMValidatedProperty(_objectSchema, property).column;
    auto value = translateErrors([&] { return (_results.*method)(column); }, methodName);
    if (!value) {
        return nil;
    }
    return RLMMixedToObjc(*value);
}

- (id)minOfProperty:(NSString *)property {
    return [self aggregate:property method:&Results::min methodName:@"minOfProperty"];
}

- (id)maxOfProperty:(NSString *)property {
    return [self aggregate:property method:&Results::max methodName:@"maxOfProperty"];
}

- (id)sumOfProperty:(NSString *)property {
    return [self aggregate:property method:&Results::sum methodName:@"sumOfProperty"];
}

- (id)averageOfProperty:(NSString *)property {
    return [self aggregate:property method:&Results::average methodName:@"averageOfProperty"];
}

- (void)deleteObjectsFromRealm {
    return translateErrors([&] {
        if (_results.get_mode() == Results::Mode::Table) {
            RLMResultsValidateInWriteTransaction(self);
            RLMClearTable(self.objectSchema);
        }
        else {
            RLMTrackDeletions(_realm, ^{ _results.clear(); });
        }
    });
}

- (NSString *)description {
    const NSUInteger maxObjects = 100;
    NSMutableString *mString = [NSMutableString stringWithFormat:@"RLMResults <0x%lx> (\n", (long)self];
    unsigned long index = 0, skipped = 0;
    for (id obj in self) {
        NSString *sub;
        if ([obj respondsToSelector:@selector(descriptionWithMaxDepth:)]) {
            sub = [obj descriptionWithMaxDepth:RLMDescriptionMaxDepth - 1];
        }
        else {
            sub = [obj description];
        }

        // Indent child objects
        NSString *objDescription = [sub stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
        [mString appendFormat:@"\t[%lu] %@,\n", index++, objDescription];
        if (index >= maxObjects) {
            skipped = self.count - maxObjects;
            break;
        }
    }

    // Remove last comma and newline characters
    if(self.count > 0)
        [mString deleteCharactersInRange:NSMakeRange(mString.length-2, 2)];
    if (skipped) {
        [mString appendFormat:@"\n\t... %lu objects skipped.", skipped];
    }
    [mString appendFormat:@"\n)"];
    return [NSString stringWithString:mString];
}

- (NSUInteger)indexInSource:(NSUInteger)index {
    return translateErrors([&] { return _results.get(index).get_index(); });
}

- (realm::TableView)tableView {
    return translateErrors([&] { return _results.get_tableview(); });
}

@end
