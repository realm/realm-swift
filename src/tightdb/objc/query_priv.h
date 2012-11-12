//
//  query_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>

#pragma mark - Private Query interface

@interface Query()
-(tightdb::TableView)getTableView;
@end
