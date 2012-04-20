//
//  OCTablePriv.h
//  TightDB
//

#import <Foundation/Foundation.h>
#import "TightDb/Table.h"

#pragma mark - Private Table interface

@interface OCTable()
@property(nonatomic) tightdb::TableRef table; 
@property(nonatomic) tightdb::Table *tablePtr;
-(tightdb::Table *)getTable;
-(void)setParent:(id)parent; // Workaround for ARC release problem.
@end
