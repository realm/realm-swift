//
//  OCTablePriv.h
//  TightDB
//

#import <Foundation/Foundation.h>
#import "Table.h"

#pragma mark - Private Table interface

@interface OCTable()
@property(nonatomic) TableRef table; 
@property(nonatomic) Table *tablePtr;
-(Table *)getTable;
-(void)setParent:(id)parent; // Workaround for ARC release problem.
-(id)initWithBlock:(TopLevelTableInitBlock)block; // This interface is only defined on the Tightdb macro defined tables.
@end
