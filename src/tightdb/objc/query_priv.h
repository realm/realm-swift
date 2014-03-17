//
//  query_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>

@interface TDBQuery()
-(tightdb::Query&)getNativeQuery;
@end
