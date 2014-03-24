//
//  NSData+TDBGetBinaryData.h
//  TightDbObjcDyn
//
//  Created by Kenneth  Geisshirt on 24/03/14.
//  Copyright (c) 2014 Thomas Andersen. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <tightdb/binary_data.hpp>

@interface NSData (TDBGetBinaryData)

-(tightdb::BinaryData) tdbBinaryData;

@end
