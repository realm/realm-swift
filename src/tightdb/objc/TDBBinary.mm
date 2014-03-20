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
#include <tightdb/binary_data.hpp>

#import "binary.h"
#import "binary_priv.h"

@implementation TDBBinary
{
    tightdb::BinaryData m_data;
}
-(id)initWithData:(const char*)data size:(size_t)size
{
    self = [super init];
    if (self) {
        m_data = tightdb::BinaryData(data, size);
    }
    return self;
}
-(id)initWithBinary:(tightdb::BinaryData)data
{
    self = [super init];
    if (self) {
        m_data = data;
    }
    return self;
}
-(const char*)getData
{
    return m_data.data();
}
-(size_t)getSize
{
    return m_data.size();
}
-(BOOL)isEqual:(TDBBinary*)bin
{
    return m_data == bin->m_data;
}
-(tightdb::BinaryData&)getNativeBinary
{
    return m_data;
}
@end