//
//  TablePriv.h
//  TightDB
//

#import <Foundation/Foundation.h>

#pragma mark - Private Table interface

@interface Table()
@property(nonatomic) tightdb::TableRef table; 
@property(nonatomic) tightdb::Table *tablePtr;
-(id)initWithTableRef:(tightdb::TableRef)ref;
-(tightdb::Table *)getTable;
-(void)setParent:(id)parent; // Workaround for ARC release problem.
@end
