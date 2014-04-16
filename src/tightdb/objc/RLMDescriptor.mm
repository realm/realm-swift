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

#include <tightdb/data_type.hpp>
#include <tightdb/descriptor.hpp>

#import "RLMType.h"
#import "RLMDescriptor.h"
#import "util_noinst.hpp"


@implementation RLMDescriptor
{
    tightdb::DescriptorRef m_desc;
    BOOL m_read_only;
}


+(RLMDescriptor *)descWithDesc:(tightdb::Descriptor*)desc readOnly:(BOOL)read_only error:(NSError* __autoreleasing*)error
{
    static_cast<void>(error);
    RLMDescriptor * desc_2 = [[RLMDescriptor alloc] init];
    desc_2->m_desc.reset(desc);
    desc_2->m_read_only = read_only;
    return desc_2;
}

// FIXME: Provide a version of this method that takes a 'const char*'. This will simplify _addColumns of MyTable.
// FIXME: Detect errors from core library
-(BOOL)addColumnWithName:(NSString*)name type:(RLMType)type
{
    return [self addColumnWithName:name andType:type error:nil];
}

-(BOOL)addColumnWithName:(NSString*)name andType:(RLMType)type error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, @"Tried to add column while read only");
        return NO;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 m_desc->add_column(tightdb::DataType(type), ObjcStringAccessor(name));,
                                 NO);
    return YES;
}

-(RLMDescriptor *)addColumnTable:(NSString*)name
{
    return [self addColumnTable:name error:nil];
}

-(RLMDescriptor *)addColumnTable:(NSString*)name error:(NSError* __autoreleasing*)error
{
    if (m_read_only) {
        if (error)
            *error = make_tightdb_error(tdb_err_FailRdOnly, @"Tried to add column while read only");
        return nil;
    }
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 tightdb::DescriptorRef subdesc;
                                 m_desc->add_column(tightdb::type_Table, ObjcStringAccessor(name), &subdesc);
                                 return [RLMDescriptor descWithDesc:subdesc.get() readOnly:FALSE error:error];,
                                 nil);
}

-(RLMDescriptor *)subdescriptorForColumnWithIndex:(NSUInteger)col_ndx
{
    return [self subdescriptorForColumnWithIndex:col_ndx error:nil];
}

-(RLMDescriptor *)subdescriptorForColumnWithIndex:(NSUInteger)col_ndx error:(NSError* __autoreleasing*)error
{
    TIGHTDB_EXCEPTION_ERRHANDLER(
                                 tightdb::DescriptorRef subdesc = m_desc->get_subdescriptor(col_ndx);
                                 return [RLMDescriptor descWithDesc:subdesc.get() readOnly:m_read_only error:error];,
                                 nil);
}

-(NSUInteger)columnCount
{
    return m_desc->get_column_count();
}

-(RLMType)columnTypeOfColumnWithIndex:(NSUInteger)colIndex
{
    return (RLMType)m_desc->get_column_type(colIndex);
}

-(NSString*)nameOfColumnWithIndex:(NSUInteger)colIndex
{
    return to_objc_string(m_desc->get_column_name(colIndex));
}

-(NSUInteger)indexOfColumnWithName:(NSString *)name
{
    return was_not_found(m_desc->get_column_index(ObjcStringAccessor(name)));
}

-(void)dealloc
{
#ifdef TIGHTDB_DEBUG
    // NSLog(@"RLMDescriptor dealloc");
#endif
}


@end
