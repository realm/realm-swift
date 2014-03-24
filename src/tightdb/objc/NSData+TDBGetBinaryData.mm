//
//  NSData+TDBGetBinaryData.m
//  TightDbObjcDyn
//
//  Created by Kenneth  Geisshirt on 24/03/14.
//  Copyright (c) 2014 Thomas Andersen. All rights reserved.
//

#import "NSData+TDBGetBinaryData.h"

#include <tightdb/binary_data.hpp>

@implementation NSData (TDBGetBinaryData)

-(tightdb::BinaryData) tdbBinaryData
{
    const void *data = [self bytes];
    return tightdb::BinaryData(static_cast<const char *>(data), [self length]);
}
@end
