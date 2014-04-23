/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/

#import <Foundation/Foundation.h>

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/table.hpp>
#include <tightdb/descriptor.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/lang_bind_helper.hpp>

#import "RLMTable_noinst.h"
#import "RLMRow.h"
#import "RLMView_noinst.h"
#import "RLMQuery_noinst.h"
#import "RLMPrivate.h"
#import "util_noinst.hpp"


@implementation RLMView
{
    tightdb::util::UniquePtr<tightdb::TableView> m_view;
    RLMTable * m_table;
    RLMRow * m_tmp_row;
    BOOL m_read_only;
    Class _proxyObjectClass;
}

+(RLMView *)viewWithTable:(RLMTable *)table nativeView:(const tightdb::TableView&)view
{
    RLMView * viewObj = [[RLMView alloc] init];
    if (!viewObj)
        return nil;
    viewObj->m_view.reset(new tightdb::TableView(view)); // FIXME: Exception handling needed here
    viewObj->m_table = table;
    viewObj->m_read_only = [table isReadOnly];

    return viewObj;
}

+(RLMView*)viewWithTable:(RLMTable*)table
              nativeView:(const tightdb::TableView&)view
             objectClass:(Class)objectClass {
    RLMView * v = [RLMView viewWithTable:table nativeView:view];
    v->_proxyObjectClass = objectClass;
    return v;
}

- (id)init {
    self = [super init];
    if (self) {
        _proxyObjectClass = RLMRow.class;
    }
    return self;
}


-(id)_initWithQuery:(RLMQuery *)query
{
    self = [super init];
    if (self) {
        tightdb::Query& queryRef = [query getNativeQuery];
        m_view.reset(new tightdb::TableView(queryRef.find_all())); // FIXME: Exception handling needed here
        m_table = [query originTable];
        m_read_only = [m_table isReadOnly];
        _proxyObjectClass = RLMRow.class;
    }
    return self;
}

-(RLMTable *)originTable // Synthesize property
{
    return m_table;
}

-(void)dealloc
{
#ifdef REALM_DEBUG
    // NSLog(@"RLMView dealloc");
#endif
    m_table = nil; // FIXME: What is the point of doing this?
}

-(RLMRow *)objectAtIndexedSubscript:(NSUInteger)ndx
{
    // The cursor constructor checks the index is in bounds. However, getSourceIndex should
    // not be called with illegal index.

    if (ndx >= self.rowCount)
        return nil;

    return [[_proxyObjectClass alloc] initWithTable:m_table ndx:[self rowIndexInOriginTableForRowAtIndex:ndx]];
}

-(RLMRow *)rowAtIndex:(NSUInteger)ndx
{
    // The cursor constructor checks the index is in bounds. However, getSourceIndex should
    // not be called with illegal index.

    if (ndx >= self.rowCount)
        return nil;

    return [[_proxyObjectClass alloc] initWithTable:m_table ndx:[self rowIndexInOriginTableForRowAtIndex:ndx]];
}

-(RLMRow *)firstRow
{
    if (self.rowCount == 0) {
        return nil;
    }
    return [[_proxyObjectClass alloc] initWithTable:m_table ndx:[self rowIndexInOriginTableForRowAtIndex:0]];
}

-(RLMRow *)lastRow
{
    if (self.rowCount == 0) {
        return nil;
    }
    return [[_proxyObjectClass alloc] initWithTable:m_table ndx:[self rowIndexInOriginTableForRowAtIndex:self.rowCount-1]];
}

-(NSUInteger)rowCount
{
    return m_view->size();
}

-(NSUInteger)columnCount
{
    return m_view->get_column_count();
}

-(RLMType)columnTypeOfColumnWithIndex:(NSUInteger)colNdx
{
    REALM_EXCEPTION_HANDLER_COLUMN_INDEX_VALID(colNdx);
    return RLMType(m_view->get_column_type(colNdx));
}

-(void)sortUsingColumnWithIndex:(NSUInteger)colIndex
{
    [self sortUsingColumnWithIndex:colIndex inOrder:RLMSortOrderAscending];
}

-(void)sortUsingColumnWithIndex:(NSUInteger)colIndex  inOrder: (RLMSortOrder)order
{
    RLMType columnType = [self columnTypeOfColumnWithIndex:colIndex];

    if(columnType != RLMTypeInt && columnType != RLMTypeBool && columnType != RLMTypeDate) {
        @throw [NSException exceptionWithName:@"realm:sort_on_column_with_type_not_supported"
                                       reason:@"Sort is currently only supported on Integer, Boolean and Date columns."
                                     userInfo:nil];
    }

    try {
        m_view->sort(colIndex, order == 0);
    } catch(std::exception& ex) {
        @throw [NSException exceptionWithName:@"realm:core_exception"
                                       reason:[NSString stringWithUTF8String:ex.what()]
                                     userInfo:nil];
    }
}

-(BOOL)RLM_boolInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_bool(colIndex, rowIndex);
}
-(NSDate *)RLM_dateInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return [NSDate dateWithTimeIntervalSince1970:m_view->get_datetime(colIndex, rowIndex).get_datetime()];
}
-(double)RLM_doubleInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_double(colIndex, rowIndex);
}
-(float)RLM_floatInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_float(colIndex, rowIndex);
}
-(int64_t)RLM_intInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return m_view->get_int(colIndex, rowIndex);
}
-(id)RLM_mixedInColumnWithIndex:(NSUInteger)colNdx atRowIndex:(NSUInteger)rowIndex
{
    tightdb::Mixed mixed = m_view->get_mixed(colNdx, rowIndex);
    if (mixed.get_type() != tightdb::type_Table)
        return to_objc_object(mixed);

    tightdb::TableRef table = m_view->get_subtable(colNdx, rowIndex);
    TIGHTDB_ASSERT(table);
    RLMTable * tableObj = [[RLMTable alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!tableObj))
        return nil;
    [tableObj setNativeTable:table.get()];
    [tableObj setParent:self];
    [tableObj setReadOnly:m_read_only];
    if (![tableObj _checkType])
        return nil;

    return tableObj;
}

-(NSString*)RLM_stringInColumnWithIndex:(NSUInteger)colIndex atRowIndex:(NSUInteger)rowIndex
{
    return to_objc_string(m_view->get_string(colIndex, rowIndex));
}


-(void)removeRowAtIndex:(NSUInteger)rowIndex
{
    if (m_read_only) {
        @throw [NSException exceptionWithName:@"realm:table_view_is_read_only"
                                       reason:@"You tried to modify an immutable tableview"
                                     userInfo:nil];
    }

    m_view->remove(rowIndex);
}
-(void)removeAllRows
{
    if (m_read_only) {
        @throw [NSException exceptionWithName:@"realm:table_view_is_read_only"
                                       reason:@"You tried to modify an immutable tableview"
                                     userInfo:nil];
    }

    m_view->clear();
}
-(NSUInteger)rowIndexInOriginTableForRowAtIndex:(NSUInteger)rowIndex
{
    return m_view->get_source_ndx(rowIndex);
}

-(RLMRow *)getRow
{
    return m_tmp_row = [[_proxyObjectClass alloc] initWithTable: m_table
                                                 ndx: m_view->get_source_ndx(0)];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id __unsafe_unretained*)stackbuf count:(NSUInteger)len
{
    static_cast<void>(len);
    if(state->state == 0) {
        const unsigned long* ptr = static_cast<const unsigned long*>(objc_unretainedPointer(self));
        state->mutationsPtr = const_cast<unsigned long*>(ptr); // FIXME: This casting away of constness seems dangerous. Is it?
        RLMRow * tmp = [self getRow];
        *stackbuf = tmp;
    }
    if (state->state < self.rowCount) {
        [((RLMRow *) *stackbuf) RLM_setNdx:[self rowIndexInOriginTableForRowAtIndex:state->state]];
        state->itemsPtr = stackbuf;
        state->state++;
    }
    else {
        *stackbuf = nil;
        state->itemsPtr = nil;
        state->mutationsPtr = nil;
        return 0;
    }
    return 1;
}

- (RLMQuery *)where
{
    RLMQuery *query = [[RLMQuery alloc] initWithTable:self.originTable error:nil];
    [query setTableView:*m_view];
    return query;
}

@end

