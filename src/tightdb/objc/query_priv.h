//
//  query_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>

@interface TightdbQuery()
-(tightdb::Query&)getNativeQuery;
@end
