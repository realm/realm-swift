//
//  query_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>


@interface TightdbGroup()
+(TightdbGroup *)groupTightdbGroup:(tightdb::Group *)tightdbGroup readOnly:(BOOL)readOnly;
-(void)clearGroup;
@end
