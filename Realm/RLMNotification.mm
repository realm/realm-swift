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

#import "RLMNotification.hpp"

#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema.h"

#import <realm/lang_bind_helper.hpp>

using namespace realm;

RLMObservationInfo::RLMObservationInfo(RLMObjectSchema *objectSchema, std::size_t row, id object)
: object(object)
, objectSchema(objectSchema)
{
    setRow(*objectSchema.table, row);
}

RLMObservationInfo::RLMObservationInfo(id object)
: object(object)
{
}

RLMObservationInfo::~RLMObservationInfo() {
    if (prev) {
        prev->next = next;
        if (next)
            next->prev = prev;
    }
    else if (objectSchema) {
        for (auto it = objectSchema->_observedObjects.begin(), end = objectSchema->_observedObjects.end(); it != end; ++it) {
            if (*it == this) {
                if (next)
                    *it = next;
                else {
                    iter_swap(it, std::prev(end));
                    objectSchema->_observedObjects.pop_back();
                }
                return;
            }
        }
    }
}

void RLMObservationInfo::setRow(realm::Table &table, size_t newRow) {
    REALM_ASSERT(!row);
    skipUnregisteringObservers = true;
    row = table[newRow];
    for (auto info : objectSchema->_observedObjects) {
        if (info->row && info->row.get_index() == row.get_index()) {
            prev = info;
            next = info->next;
            info->next = this;
            return;
        }
    }
    objectSchema->_observedObjects.push_back(this);
}

void RLMObservationInfo::recordObserver(realm::Row& objectRow,
                                        __unsafe_unretained RLMObjectSchema *const objectSchema,
                                        __unsafe_unretained id const observer,
                                        __unsafe_unretained NSString *const keyPath,
                                        NSKeyValueObservingOptions options,
                                        void *context) {
    // add ourselves to the list of observed objects if this is the first time
    // an observer is being added to a persisted object
    if (objectRow && !row) {
        this->objectSchema = objectSchema;
        setRow(*objectRow.get_table(), objectRow.get_index());
    }

    // record the observation if the object is standalone
    if (!row) {
        standaloneObservers.push_back({observer, options, context, keyPath});
    }
}

template<typename Container, typename Pred>
static void erase_first(Container&& c, Pred&& p) {
    auto it = find_if(c.begin(), c.end(), p);
    assert(it != c.end());
    if (it != c.end()) {
        iter_swap(it, prev(c.end()));
        c.pop_back();
    }
}

void RLMObservationInfo::removeObserver(__unsafe_unretained id const observer,
                                        __unsafe_unretained NSString *const keyPath) {
    if (!skipUnregisteringObservers) {
        erase_first(standaloneObservers, [&](auto const& info) {
            return info.observer == observer && [info.key isEqualToString:keyPath];
        });
    }
}

void RLMObservationInfo::removeObserver(__unsafe_unretained id const observer,
                                        __unsafe_unretained NSString *const keyPath,
                                        void *context) {
    if (!skipUnregisteringObservers) {
        erase_first(standaloneObservers, [&](auto const& info) {
            return info.observer == observer
                && info.context == context
                && [info.key isEqualToString:keyPath];
        });
    }
}

void RLMObservationInfo::removeObservers() {
   skipUnregisteringObservers  = true;
    for (auto const& info : standaloneObservers) {
        [object removeObserver:info.observer forKeyPath:info.key context:info.context];
    }

}

void RLMObservationInfo::restoreObservers() {
    for (auto const& info : standaloneObservers) {
        [object addObserver:info.observer
                 forKeyPath:info.key
                    options:info.options & ~NSKeyValueObservingOptionInitial
                    context:info.context];
    }
    standaloneObservers.clear();
}

RLMObservationInfo *RLMGetObservationInfo(std::unique_ptr<RLMObservationInfo> const& info,
                                          size_t row,
                                          __unsafe_unretained RLMObjectSchema *objectSchema) {
    if (info) {
        return info.get();
    }

    for (RLMObservationInfo *info : objectSchema->_observedObjects) {
        if (info->row.get_index() == row) {
            return info;
        }
    }

    return nullptr;
}

void RLMForEachObserver(RLMObjectBase *obj, void (^block)(RLMObjectBase*)) {
    RLMObservationInfo *info = RLMGetObservationInfo(obj->_observationInfo, obj->_row.get_index(), obj->_objectSchema);
    for_each(info, block);
}

void RLMTrackDeletions(__unsafe_unretained RLMRealm *const realm, dispatch_block_t block) {
    struct change {
        RLMObservationInfo *info;
        __unsafe_unretained NSString *property;
    };
    std::vector<change> changes;
    struct arrayChange {
        RLMObservationInfo *info;
        __unsafe_unretained NSString *property;
        NSMutableIndexSet *indexes;
    };
    std::vector<arrayChange> arrayChanges;

    realm.group->set_cascade_notification_handler([&](realm::Group::CascadeNotification const& cs) {
        for (auto const& row : cs.rows) {
            for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
                if (objectSchema.table->get_index_in_group() != row.table_ndx)
                    continue;
                for (auto observer : objectSchema->_observedObjects) {
                    if (observer->row && observer->row.get_index() == row.row_ndx) {
                        changes.push_back({observer, @"invalidated"});
                        for (RLMProperty *prop in objectSchema.properties)
                            changes.push_back({observer, prop.name});
                        break;
                    }
                }
                break;
            }
        }
        for (auto const& link : cs.links) {
            for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
                if (objectSchema.table->get_index_in_group() != link.origin_table->get_index_in_group())
                    continue;
                for (auto observer : objectSchema->_observedObjects) {
                    if (observer->row.get_index() != link.origin_row_ndx)
                        continue;
                    RLMProperty *prop = objectSchema.properties[link.origin_col_ndx];
                    NSString *name = prop.name;
                    if (prop.type != RLMPropertyTypeArray)
                        changes.push_back({observer, name});
                    else {
                        auto linkview = observer->row.get_linklist(prop.column);
                        arrayChange *c = nullptr;
                        for (auto& ac : arrayChanges) {
                            if (ac.info == observer && ac.property == name) {
                                c = &ac;
                                break;
                            }
                        }
                        if (!c) {
                            arrayChanges.push_back({observer, name, [NSMutableIndexSet new]});
                            c = &arrayChanges.back();
                        }

                        size_t start = 0, index;
                        while ((index = linkview->find(link.old_target_row_ndx, start)) != realm::not_found) {
                            [c->indexes addIndex:index];
                            start = index + 1;
                        }
                    }
                    break;
               }
                break;
            }
        }

        for (auto const& change : changes)
            for_each(change.info, [&](auto o) { [o willChangeValueForKey:change.property]; });
        for (auto const& change : arrayChanges)
            for_each(change.info, [&](auto o) { [o willChange:NSKeyValueChangeRemoval valuesAtIndexes:change.indexes forKey:change.property]; });
    });

    block();

    for (auto const& change : changes) {
        change.info->setReturnNil(true);
        for_each(change.info, [&](auto o) { [o didChangeValueForKey:change.property]; });
    }
    for (auto const& change : arrayChanges) {
        change.info->setReturnNil(true);
        for_each(change.info, [&](auto o) { [o didChange:NSKeyValueChangeRemoval valuesAtIndexes:change.indexes forKey:change.property]; });
    }

    realm.group->set_cascade_notification_handler(nullptr);
}

struct ObserverState {
    size_t table;
    size_t row;
    size_t column;
    NSString *key;
    RLMObservationInfo *info;

    bool changed = false;
    bool multipleLinkviewChanges = false;
    NSKeyValueChange linkviewChangeKind = NSKeyValueChangeSetting;
    NSMutableIndexSet *linkviewChangeIndexes;
};

class TransactLogHandler {
    size_t current_table = 0;
    ObserverState *active_linklist = nullptr;
    std::vector<ObserverState> observers;

    void findObservers(NSArray *schema) {
        // all this should maybe be precomputed or cached or something
        for (RLMObjectSchema *objectSchema in schema) {
            for (auto info : objectSchema->_observedObjects) {
                auto const& row = info->row;
                if (!row.is_attached()) // FIXME: should maybe try to remove from array on invalidate
                    continue;
                info->setReturnNil(false);
                observers.push_back({
                    row.get_table()->get_index_in_group(),
                    row.get_index(),
                    realm::npos,
                    @"invalidated",
                    info});
                for (size_t i = 0; i < objectSchema.properties.count; ++i) {
                    observers.push_back({
                        row.get_table()->get_index_in_group(),
                        row.get_index(),
                        i,
                        [objectSchema.properties[i] name],
                        info});
                }
            }
        }
    }

    void notifyObservers() {
        for (auto const& o : observers) {
            if (o.row == realm::not_found && o.column == realm::npos) {
                for_each(o.info, [&](auto obj) { [obj didChangeValueForKey:o.key]; });
            }
            if (!o.changed)
                continue;
            if (!o.linkviewChangeIndexes)
                for_each(o.info, [&](auto obj) { [obj didChangeValueForKey:o.key]; });
            else {
                for_each(o.info, [&](auto obj) {
                    [obj didChange:o.linkviewChangeKind valuesAtIndexes:o.linkviewChangeIndexes forKey:o.key];
                });
            }
        }
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

    void parse_complete() {
        for (auto const& o : observers) {
            if (o.row == realm::not_found) {
                if (o.column == realm::npos)
                    for_each(o.info, [&](auto obj) { [obj willChangeValueForKey:o.key]; });
                else {
                    o.info->setReturnNil(false);
                    for_each(o.info, [&](auto obj) { [obj willChangeValueForKey:o.key]; });
                    o.info->setReturnNil(true);
                    for_each(o.info, [&](auto obj) { [obj didChangeValueForKey:o.key]; });
                }
            }
            if (!o.changed)
                continue;
            if (!o.linkviewChangeIndexes)
                for_each(o.info, [&](auto obj) { [obj willChangeValueForKey:o.key]; });
            else {
                for_each(o.info, [&](auto obj) {
                    [obj willChange:o.linkviewChangeKind valuesAtIndexes:o.linkviewChangeIndexes forKey:o.key];
                });
            }
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
        current_table = group_level_ndx;
        return true;
    }

    bool insert_empty_rows(size_t, size_t, size_t, bool) {
        // rows are only inserted at the end, so no need to do anything
        return true;
    }

    bool erase_rows(size_t row_ndx, size_t, size_t last_row_ndx, bool unordered) noexcept {
        for (auto& o : observers) {
            if (o.table == current_table) {
                if (o.row == row_ndx) {
                    o.row = realm::npos;
                    o.changed = false;
                }
                else if (unordered && o.row == last_row_ndx) {
                    o.row = row_ndx;
                }
                else if (!unordered && o.row > row_ndx && o.row != realm::npos) {
                    o.row -= 1;
                }
            }
        }
        return true;
    }

    bool clear_table() noexcept {
        for (auto& o : observers) {
            if (o.table == current_table) {
                o.row = realm::npos;
                o.changed = false;
            }
        }
        return true;
    }

    bool select_link_list(size_t col, size_t row) {
        active_linklist = nullptr;
        for (auto& o : observers) {
            if (o.table == current_table && o.row == row && o.column == col) {
                active_linklist = &o;
                break;
            }
        }
        return true;
    }

    void append_link_list_change(NSKeyValueChange kind, NSUInteger index) {
        if (ObserverState *o = active_linklist) {
            if (o->multipleLinkviewChanges)
                return;
            if (!o->linkviewChangeIndexes) {
                o->linkviewChangeIndexes = [NSMutableIndexSet indexSetWithIndex:index];
                o->linkviewChangeKind = kind;
                o->changed = true;
            }
            else if (o->linkviewChangeKind == kind) {
                if (kind == NSKeyValueChangeRemoval) {
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
                o->multipleLinkviewChanges = false;
                o->linkviewChangeIndexes = nil;
            }
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

    bool link_list_clear() {
        if (ObserverState *o = active_linklist) {
            if (o->multipleLinkviewChanges)
                return true;

            auto range = NSMakeRange(0, o->info->row.get_linklist(o->column)->size());
            if (!o->linkviewChangeIndexes) {
                o->linkviewChangeIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:range];
                o->linkviewChangeKind = NSKeyValueChangeRemoval;
            }
            else if (o->linkviewChangeKind == NSKeyValueChangeRemoval) {
                // FIXME: not tested
                range.length += [o->linkviewChangeIndexes count];
                [o->linkviewChangeIndexes addIndexesInRange:range];
            }
            // FIXME: clear after insert doesn't need to set multiple
            else {
                o->multipleLinkviewChanges = false;
                o->linkviewChangeIndexes = nil;
            }
            o->changed = true;
        }
        return true;
    }

    bool link_list_move(size_t, size_t) { return true; }

    // Things that just mark the field as modified
    bool set_int(size_t col, size_t row, int_fast64_t) { return mark_dirty(row, col); }
    bool set_bool(size_t col, size_t row, bool) { return mark_dirty(row, col); }
    bool set_float(size_t col, size_t row, float) { return mark_dirty(row, col); }
    bool set_double(size_t col, size_t row, double) { return mark_dirty(row, col); }
    bool set_string(size_t col, size_t row, StringData) { return mark_dirty(row, col); }
    bool set_binary(size_t col, size_t row, BinaryData) { return mark_dirty(row, col); }
    bool set_date_time(size_t col, size_t row, DateTime) { return mark_dirty(row, col); }
    bool set_table(size_t col, size_t row) { return mark_dirty(row, col); }
    bool set_mixed(size_t col, size_t row, const Mixed&) { return mark_dirty(row, col); }
    bool set_link(size_t col, size_t row, size_t) { return mark_dirty(row, col); }
    bool set_null(size_t col, size_t row) { return mark_dirty(row, col); }
    bool nullify_link(size_t col, size_t row) { return mark_dirty(row, col); }

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

private:
    bool mark_dirty(size_t row_ndx, size_t col_ndx) {
        for (auto& o : observers) {
            if (o.table == current_table && o.row == row_ndx && o.column == col_ndx) {
                o.changed = true;
            }
        }
        return true;
    }
};

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
