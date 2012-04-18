//
//  OCTablePriv.h
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark - Private Table interface

@interface OCTable()
@property(nonatomic) TableRef table; 
@property(nonatomic) Table *tablePtr;
-(Table *)getTable;
-(id)initWithBlock:(TopLevelTableInitBlock)block; // This interface is only defined on the Tightdb macro defined tables.
@end
