//
//  query_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>


@interface TightdbGroup()

+(TightdbGroup*)groupWithNativeGroup:(tightdb::Group*)group isOwned:(BOOL)is_owned readOnly:(BOOL)read_only;

@end
