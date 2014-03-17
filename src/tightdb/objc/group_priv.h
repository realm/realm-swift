//
//  query_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>


@interface TDBGroup()

+(TDBGroup*)groupWithNativeGroup:(tightdb::Group*)group isOwned:(BOOL)is_owned readOnly:(BOOL)read_only;

@end
