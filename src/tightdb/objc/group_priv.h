//
//  query_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>


@interface TDBTransaction()

+(TDBTransaction*)groupWithNativeGroup:(tightdb::Group*)group isOwned:(BOOL)is_owned readOnly:(BOOL)read_only;

@end
