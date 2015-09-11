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

#import "RLMObservation.hpp"

#import "RLMAccessor.h"
#import "RLMArray_Private.hpp"
#import "RLMListBase.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema.h"

#import <realm/lang_bind_helper.hpp>

using namespace realm;

namespace {
    template<typename Iterator>
    struct IteratorPair {
        Iterator first;
        Iterator second;
    };
    template<typename Iterator>
    Iterator begin(IteratorPair<Iterator> const& p) {
        return p.first;
    }
    template<typename Iterator>
    Iterator end(IteratorPair<Iterator> const& p) {
        return p.second;
    }

    template<typename Container>
    auto reverse(Container const& c) {
        return IteratorPair<typename Container::const_reverse_iterator>{c.rbegin(), c.rend()};
    }
}

RLMObservationInfo::RLMObservationInfo(RLMObjectSchema *objectSchema, std::size_t row, id object)
: object(object)
, objectSchema(objectSchema)
{
    REALM_ASSERT_DEBUG(objectSchema);
    setRow(*objectSchema.table, row);
}

RLMObservationInfo::RLMObservationInfo(id object)
: object(object)
{
}

RLMObservationInfo::~RLMObservationInfo() {
    if (prev) {
        // Not the head of the linked list, so just detach from the list
        REALM_ASSERT_DEBUG(prev->next == this);
        prev->next = next;
        if (next) {
            REALM_ASSERT_DEBUG(next->prev == this);
            next->prev = prev;
        }
    }
    else if (objectSchema) {
        // The head of the list, so remove self from the object schema's array
        // of observation info, either replacing self with the next info or
        // removing entirely if there is no next
        auto end = objectSchema->_observedObjects.end();
        auto it = find(objectSchema->_observedObjects.begin(), end, this);
        if (it != end) {
            if (next) {
                *it = next;
                next->prev = nullptr;
            }
            else {
                iter_swap(it, std::prev(end));
                objectSchema->_observedObjects.pop_back();
            }
        }
    }
    // Otherwise the observed object was standalone, so nothing to do

#ifdef DEBUG
    // ensure that incorrect cleanup fails noisily
    object = (__bridge id)(void *)-1;
    prev = (RLMObservationInfo *)-1;
    next = (RLMObservationInfo *)-1;
#endif
}

void RLMObservationInfo::willChange(NSString *key, NSKeyValueChange kind, NSIndexSet *indexes) const {
    if (indexes) {
        forEach([=](__unsafe_unretained auto o) {
            [o willChange:kind valuesAtIndexes:indexes forKey:key];
        });
    }
    else {
        forEach([=](__unsafe_unretained auto o) {
            [o willChangeValueForKey:key];
        });
    }
}

void RLMObservationInfo::didChange(NSString *key, NSKeyValueChange kind, NSIndexSet *indexes) const {
    if (indexes) {
        forEach([=](__unsafe_unretained auto o) {
            [o didChange:kind valuesAtIndexes:indexes forKey:key];
        });
    }
    else {
        forEach([=](__unsafe_unretained auto o) {
            [o didChangeValueForKey:key];
        });
    }
}

void RLMObservationInfo::prepareForInvalidation() {
    REALM_ASSERT_DEBUG(objectSchema);
    REALM_ASSERT_DEBUG(!prev);
    for (auto info = this; info; info = info->next)
        info->invalidated = true;
}

void RLMObservationInfo::setRow(realm::Table &table, size_t newRow) {
    REALM_ASSERT_DEBUG(!row);
    REALM_ASSERT_DEBUG(objectSchema);
    row = table[newRow];
    for (auto info : objectSchema->_observedObjects) {
        if (info->row && info->row.get_index() == row.get_index()) {
            prev = info;
            next = info->next;
            if (next)
                next->prev = this;
            info->next = this;
            return;
        }
    }
    objectSchema->_observedObjects.push_back(this);
}

void RLMObservationInfo::recordObserver(realm::Row& objectRow,
                                        __unsafe_unretained RLMObjectSchema *const objectSchema,
                                        __unsafe_unretained NSString *const keyPath) {
    ++observerCount;

    // add ourselves to the list of observed objects if this is the first time
    // an observer is being added to a persisted object
    if (objectRow && !row) {
        this->objectSchema = objectSchema;
        setRow(*objectRow.get_table(), objectRow.get_index());
    }

    if (!row) {
        // Arrays need a reference to their containing object to avoid having to
        // go through the awful proxy object from mutableArrayValueForKey.
        // For persisted objects we do this when the object is added or created
        // (and have to to support notifications from modifying an object which
        // was never observed), but for Swift classes (both RealmSwift and
        // RLMObject) we can't do it then because we don't know what the parent
        // object is.

        NSUInteger sep = [keyPath rangeOfString:@"."].location;
        NSString *key = sep == NSNotFound ? keyPath : [keyPath substringToIndex:sep];
        RLMProperty *prop = objectSchema[key];
        if (prop && prop.type == RLMPropertyTypeArray) {
            id value = valueForKey(key);
            RLMArray *array = [value isKindOfClass:[RLMListBase class]] ? [value _rlmArray] : value;
            array->_key = key;
            array->_parentObject = object;
        }
        else if (auto swiftIvar = prop.swiftIvar) {
            if (auto optional = RLMDynamicCast<RLMOptionalBase>(object_getIvar(object, swiftIvar))) {
                optional.property = prop;
                optional.object = object;
            }
        }
    }
}

void RLMObservationInfo::removeObserver() {
    --observerCount;
}

id RLMObservationInfo::valueForKey(NSString *key) {
    if (invalidated) {
        if ([key isEqualToString:RLMInvalidatedKey]) {
            return @YES;
        }
        return cachedObjects[key];
    }

    if (key != lastKey) {
        lastKey = key;
        lastProp = objectSchema[key];
    }

    static auto superValueForKey = reinterpret_cast<id(*)(id, SEL, NSString *)>([NSObject methodForSelector:@selector(valueForKey:)]);
    if (!lastProp) {
        return RLMCoerceToNil(superValueForKey(object, @selector(valueForKey:), key));
    }

    auto getSuper = [&] {
        return row ? RLMDynamicGet(object, lastProp) : RLMCoerceToNil(superValueForKey(object, @selector(valueForKey:), key));
    };

    // We need to return the same object each time for observing over keypaths to work
    if (lastProp.type == RLMPropertyTypeArray) {
        RLMArray *value = cachedObjects[key];
        if (!value) {
            value = getSuper();
            if (!cachedObjects) {
                cachedObjects = [NSMutableDictionary new];
            }
            cachedObjects[key] = value;
        }
        return value;
    }

    if (lastProp.type == RLMPropertyTypeObject) {
        if (row.is_null_link(lastProp.column)) {
            [cachedObjects removeObjectForKey:key];
            return nil;
        }

        RLMObjectBase *value = cachedObjects[key];
        if (value && value->_row.get_index() == row.get_link(lastProp.column)) {
            return value;
        }
        value = getSuper();
        if (!cachedObjects) {
            cachedObjects = [NSMutableDictionary new];
        }
        cachedObjects[key] = value;
        return value;
    }

    return getSuper();
}

RLMObservationInfo *RLMGetObservationInfo(RLMObservationInfo *info,
                                          size_t row,
                                          __unsafe_unretained RLMObjectSchema *objectSchema) {
    if (info) {
        return info;
    }

    for (RLMObservationInfo *info : objectSchema->_observedObjects) {
        if (info->isForRow(row)) {
            return info;
        }
    }

    return nullptr;
}

void RLMClearTable(RLMObjectSchema *objectSchema) {
    for (auto info : objectSchema->_observedObjects) {
        info->willChange(RLMInvalidatedKey);
    }

    RLMTrackDeletions(objectSchema.realm, ^{
        objectSchema.table->clear();

        for (auto info : objectSchema->_observedObjects) {
            info->prepareForInvalidation();
        }
    });

    for (auto info : reverse(objectSchema->_observedObjects)) {
        info->didChange(RLMInvalidatedKey);
    }

    objectSchema->_observedObjects.clear();
}

void RLMTrackDeletions(__unsafe_unretained RLMRealm *const realm, dispatch_block_t block) {
    std::vector<std::vector<RLMObservationInfo *> *> observers;

    // Build up an array of observation info arrays which is indexed by table
    // index (the object schemata may be in an entirely different order)
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        if (objectSchema->_observedObjects.empty()) {
            continue;
        }
        size_t ndx = objectSchema.table->get_index_in_group();
        if (ndx >= observers.size()) {
            observers.resize(std::max(observers.size() * 2, ndx + 1));
        }
        observers[ndx] = &objectSchema->_observedObjects;
    }

    // No need for change tracking if no objects are observed
    if (observers.empty()) {
        block();
        return;
    }

    struct change {
        RLMObservationInfo *info;
        __unsafe_unretained NSString *property;
        NSMutableIndexSet *indexes;
    };

    std::vector<change> changes;
    std::vector<RLMObservationInfo *> invalidated;

    // This callback is called by core with a list of row deletions and
    // resulting link nullifications immediately before things are deleted and nullified
    realm.group->set_cascade_notification_handler([&](realm::Group::CascadeNotification const& cs) {
        for (auto const& link : cs.links) {
            size_t table_ndx = link.origin_table->get_index_in_group();
            if (table_ndx >= observers.size() || !observers[table_ndx]) {
                // The modified table has no observers
                continue;
            }

            for (auto observer : *observers[table_ndx]) {
                if (!observer->isForRow(link.origin_row_ndx)) {
                    continue;
                }

                RLMProperty *prop = observer->getObjectSchema().properties[link.origin_col_ndx];
                NSString *name = prop.name;
                if (prop.type != RLMPropertyTypeArray) {
                    changes.push_back({observer, name});
                    continue;
                }

                auto c = find_if(begin(changes), end(changes), [&](auto const& c) {
                    return c.info == observer && c.property == name;
                });
                if (c == end(changes)) {
                    changes.push_back({observer, name, [NSMutableIndexSet new]});
                    c = prev(end(changes));
                }

                // We know what row index is being removed from the LinkView,
                // but what we actually want is the indexes in the LinkView that
                // are going away
                auto linkview = observer->getRow().get_linklist(prop.column);
                size_t start = 0, index;
                while ((index = linkview->find(link.old_target_row_ndx, start)) != realm::not_found) {
                    [c->indexes addIndex:index];
                    start = index + 1;
                }
            }
        }

        for (auto const& row : cs.rows) {
            if (row.table_ndx >= observers.size() || !observers[row.table_ndx]) {
                // The modified table has no observers
                continue;
            }

            for (auto observer : *observers[row.table_ndx]) {
                if (observer->isForRow(row.row_ndx)) {
                    invalidated.push_back(observer);
                    break;
                }
            }
        }

        // The relative order of these loops is very important
        for (auto info : invalidated) {
            info->willChange(RLMInvalidatedKey);
        }
        for (auto const& change : changes) {
            change.info->willChange(change.property, NSKeyValueChangeRemoval, change.indexes);
        }
        for (auto info : invalidated) {
            info->prepareForInvalidation();
        }
    });

    block();

    for (auto const& change : reverse(changes)) {
        change.info->didChange(change.property, NSKeyValueChangeRemoval, change.indexes);
    }
    for (auto info : reverse(invalidated)) {
        info->didChange(RLMInvalidatedKey);
    }

    realm.group->set_cascade_notification_handler(nullptr);
}

namespace {
class TransactLogHandler {
    // For advance_read() and friends, we need to batch up the change
    // notifications and send them all at once, since all of the changes are
    // applied atomically. ObserverState tracks everything needed to send the
    // notifications for a single observed row.
    struct ObserverState {
        size_t table;
        size_t row;
        RLMObservationInfo *info;

        // Change information for a single property/column
        struct change {
            bool changed = false;
            bool multipleLinkviewChanges = false;
            NSKeyValueChange linkviewChangeKind = NSKeyValueChangeSetting;
            NSMutableIndexSet *linkviewChangeIndexes = nil;
        };
        std::vector<change> changes;

        // Get the change info for the given column, creating it if needed
        change& getChange(size_t i) {
            if (changes.size() <= i) {
                changes.resize(std::max(changes.size() * 2, i + 1));
            }
            return changes[i];
        }

        // Loop over the columns which were changed
        template<typename Func>
        void forEach(Func&& f) const {
            for (size_t i = 0; i < changes.size(); ++i) {
                auto const& change = changes[i];
                if (change.changed) {
                    f(i, change);
                }
            }
        }

        // Simple lexographic ordering
        friend bool operator<(ObserverState const& lft, ObserverState const& rgt) {
            return std::tie(lft.table, lft.row) < std::tie(rgt.table, rgt.row);
        }
    };

    size_t currentTable = 0;
    std::vector<ObserverState> observers;
    std::vector<RLMObservationInfo *> invalidated;

    ObserverState::change *activeLinkList = nullptr;

    // Find all observed objects in the given object schema and build up the
    // array of observers to notify from them
    void findObservers(NSArray *schema) {
        for (RLMObjectSchema *objectSchema in schema) {
            for (auto info : objectSchema->_observedObjects) {
                auto const& row = info->getRow();
                if (!row.is_attached())
                    continue;
                observers.push_back({
                    row.get_table()->get_index_in_group(),
                    row.get_index(),
                    info});
            }
        }
        sort(begin(observers), end(observers));
    }

    // Send didChange notifications to all observers marked as needing them
    // Loop in reverse order to avoid O(N^2) behavior in Foundation
    void notifyObservers() {
        for (auto const& o : reverse(observers)) {
            o.forEach([&](size_t i, auto const& change) {
                o.info->didChange([o.info->getObjectSchema().properties[i] name],
                                  change.linkviewChangeKind,
                                  change.linkviewChangeIndexes);
            });
        }
        for (auto const& info : reverse(invalidated)) {
            info->didChange(RLMInvalidatedKey);
        }
    }

    // Mark the given row/col as needing notifications sent
    bool markDirty(size_t row_ndx, size_t col_ndx) {
        auto it = lower_bound(begin(observers), end(observers), ObserverState{currentTable, row_ndx, nullptr});
        if (it != end(observers) && it->table == currentTable && it->row == row_ndx) {
            it->getChange(col_ndx).changed = true;
        }
        return true;
    }

    // Remove the given observer from the list of observed objects and add it
    // to the listed of invalidated objects
    void invalidate(ObserverState *o) {
        invalidated.push_back(o->info);
        observers.erase(observers.begin() + (o - &observers[0]));
    }

public:
    template<typename Func>
    TransactLogHandler(NSArray *schema, Func&& func) {
        findObservers(schema);
        if (observers.empty()) {
            func();
            return;
        }

        func(*this);
        notifyObservers();
    }

    // Called at the end of the transaction log immediately before the version
    // is advanced
    void parse_complete() {
        for (auto info : invalidated) {
            info->willChange(RLMInvalidatedKey);
        }
        for (auto const& o : observers) {
            o.forEach([&](size_t i, auto const& change) {
                o.info->willChange([o.info->getObjectSchema().properties[i] name],
                                   change.linkviewChangeKind,
                                   change.linkviewChangeIndexes);
            });
        }
        for (auto info : invalidated) {
            info->prepareForInvalidation();
        }
    }

    // These would require having an observer before schema init
    // Maybe do something here to throw an error when multiple processes have different schemas?
    bool insert_group_level_table(size_t, size_t, StringData) noexcept { return false; }
    bool erase_group_level_table(size_t, size_t) noexcept { return false; }
    bool rename_group_level_table(size_t, StringData) noexcept { return false; }
    bool insert_column(size_t, DataType, StringData, bool) { return false; }
    bool insert_link_column(size_t, DataType, StringData, size_t, size_t) { return false; }
    bool erase_column(size_t) { return false; }
    bool erase_link_column(size_t, size_t, size_t) { return false; }
    bool rename_column(size_t, StringData) { return false; }
    bool add_search_index(size_t) { return false; }
    bool remove_search_index(size_t) { return false; }
    bool add_primary_key(size_t) { return false; }
    bool remove_primary_key() { return false; }
    bool set_link_type(size_t, LinkType) { return false; }

    bool select_table(size_t group_level_ndx, int, const size_t*) noexcept {
        currentTable = group_level_ndx;
        return true;
    }

    bool insert_empty_rows(size_t, size_t, size_t, bool) {
        // rows are only inserted at the end, so no need to do anything
        return true;
    }

    bool erase_rows(size_t row_ndx, size_t, size_t last_row_ndx, bool unordered) noexcept {
        for (size_t i = 0; i < observers.size(); ++i) {
            auto& o = observers[i];
            if (o.table == currentTable) {
                if (o.row == row_ndx) {
                    invalidate(&o);
                    --i;
                }
                else if (unordered && o.row == last_row_ndx) {
                    o.row = row_ndx;
                }
                else if (!unordered && o.row > row_ndx) {
                    o.row -= 1;
                }
            }
        }
        return true;
    }

    bool clear_table() noexcept {
        for (size_t i = 0; i < observers.size(); ) {
            auto& o = observers[i];
            if (o.table == currentTable) {
                invalidate(&o);
            }
            else {
                ++i;
            }
        }
        return true;
    }

    bool select_link_list(size_t col, size_t row) {
        activeLinkList = nullptr;
        for (auto& o : observers) {
            if (o.table == currentTable && o.row == row) {
                activeLinkList = &o.getChange(col);
                break;
            }
        }
        return true;
    }

    void append_link_list_change(NSKeyValueChange kind, NSUInteger index) {
        ObserverState::change *o = activeLinkList;
        if (!o || o->multipleLinkviewChanges) {
            return;
        }

        if (!o->linkviewChangeIndexes) {
            o->linkviewChangeIndexes = [NSMutableIndexSet indexSetWithIndex:index];
            o->linkviewChangeKind = kind;
            o->changed = true;
        }
        else if (o->linkviewChangeKind == kind) {
            if (kind == NSKeyValueChangeRemoval) {
                // Shift the index to compensate for already-removed indices
                NSUInteger i = [o->linkviewChangeIndexes firstIndex];
                while (i <= index) {
                    ++index;
                    i = [o->linkviewChangeIndexes indexGreaterThanIndex:i];
                }
            }
            else if (kind == NSKeyValueChangeInsertion) {
                [o->linkviewChangeIndexes shiftIndexesStartingAtIndex:index by:1];
            }
            [o->linkviewChangeIndexes addIndex:index];
        }
        else {
            // Array KVO can only send a single kind of change at a time, so
            // if there's multiple just give up and send "Set"
            o->multipleLinkviewChanges = true;
            o->linkviewChangeIndexes = nil;
        }
    }

    bool link_list_set(size_t index, size_t) {
        append_link_list_change(NSKeyValueChangeReplacement, index);
        return true;
    }

    bool link_list_insert(size_t index, size_t) {
        append_link_list_change(NSKeyValueChangeInsertion, index);
        return true;
    }

    bool link_list_erase(size_t index) {
        append_link_list_change(NSKeyValueChangeRemoval, index);
        return true;
    }

    bool link_list_nullify(size_t index) {
        append_link_list_change(NSKeyValueChangeRemoval, index);
        return true;
    }

    bool link_list_swap(size_t index1, size_t index2) {
        append_link_list_change(NSKeyValueChangeReplacement, index1);
        append_link_list_change(NSKeyValueChangeReplacement, index2);
        return true;
    }

    bool link_list_clear(size_t old_size) {
        ObserverState::change *o = activeLinkList;
        if (!o || o->multipleLinkviewChanges) {
            return true;
        }

        NSRange range{0, old_size};
        if (!o->linkviewChangeIndexes) {
            o->linkviewChangeIndexes = [NSMutableIndexSet indexSet];
        }
        else if (o->linkviewChangeKind == NSKeyValueChangeRemoval) {
            range.length += [o->linkviewChangeIndexes count];
        }
        else if (o->linkviewChangeKind == NSKeyValueChangeInsertion) {
            range.length -= [o->linkviewChangeIndexes count];
            [o->linkviewChangeIndexes removeAllIndexes];
        }
        else { // Replacement
            [o->linkviewChangeIndexes removeAllIndexes];
        }
        o->linkviewChangeKind = NSKeyValueChangeRemoval;
        [o->linkviewChangeIndexes addIndexesInRange:range];
        o->changed = true;
        return true;
    }

    bool link_list_move(size_t from, size_t to) {
        ObserverState::change *o = activeLinkList;
        if (!o || o->multipleLinkviewChanges) {
            return true;
        }
        if (from > to) {
            std::swap(from, to);
        }

        NSRange range{from, to - from + 1};
        if (!o->linkviewChangeIndexes) {
            o->linkviewChangeIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:range];
            o->linkviewChangeKind = NSKeyValueChangeReplacement;
            o->changed = true;
        }
        else if (o->linkviewChangeKind == NSKeyValueChangeReplacement) {
            [o->linkviewChangeIndexes addIndexesInRange:range];
        }
        else {
            o->linkviewChangeIndexes = nil;
            o->multipleLinkviewChanges = true;
        }
        return true;
    }

    // Things that just mark the field as modified
    bool set_int(size_t col, size_t row, int_fast64_t) { return markDirty(row, col); }
    bool set_bool(size_t col, size_t row, bool) { return markDirty(row, col); }
    bool set_float(size_t col, size_t row, float) { return markDirty(row, col); }
    bool set_double(size_t col, size_t row, double) { return markDirty(row, col); }
    bool set_string(size_t col, size_t row, StringData) { return markDirty(row, col); }
    bool set_binary(size_t col, size_t row, BinaryData) { return markDirty(row, col); }
    bool set_date_time(size_t col, size_t row, DateTime) { return markDirty(row, col); }
    bool set_table(size_t col, size_t row) { return markDirty(row, col); }
    bool set_mixed(size_t col, size_t row, const Mixed&) { return markDirty(row, col); }
    bool set_link(size_t col, size_t row, size_t) { return markDirty(row, col); }
    bool set_null(size_t col, size_t row) { return markDirty(row, col); }
    bool nullify_link(size_t col, size_t row) { return markDirty(row, col); }

    // Things we don't need to do anything for
    bool optimize_table() { return false; }

    // Things that we don't do in the binding
    bool select_descriptor(int, const size_t*) { return true; }
    bool row_insert_complete() { return false; }
    bool add_int_to_column(size_t, int_fast64_t) { return false; }
    bool insert_int(size_t, size_t, size_t, int_fast64_t) { return false; }
    bool insert_bool(size_t, size_t, size_t, bool) { return false; }
    bool insert_float(size_t, size_t, size_t, float) { return false; }
    bool insert_double(size_t, size_t, size_t, double) { return false; }
    bool insert_string(size_t, size_t, size_t, StringData) { return false; }
    bool insert_binary(size_t, size_t, size_t, BinaryData) { return false; }
    bool insert_date_time(size_t, size_t, size_t, DateTime) { return false; }
    bool insert_table(size_t, size_t, size_t) { return false; }
    bool insert_mixed(size_t, size_t, size_t, const Mixed&) { return false; }
    bool insert_link(size_t, size_t, size_t, size_t) { return false; }
    bool insert_link_list(size_t, size_t, size_t) { return false; }
};
}

void RLMAdvanceRead(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema) {
    TransactLogHandler(schema.objectSchema, [&](auto&&... args) {
        LangBindHelper::advance_read(sg, history, std::move(args)...);
    });
}

void RLMRollbackAndContinueAsRead(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema) {
    TransactLogHandler(schema.objectSchema, [&](auto&&... args) {
        LangBindHelper::rollback_and_continue_as_read(sg, history, std::move(args)...);
    });
}

void RLMPromoteToWrite(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema) {
    TransactLogHandler(schema.objectSchema, [&](auto&&... args) {
        LangBindHelper::promote_to_write(sg, history, std::move(args)...);
    });
}
