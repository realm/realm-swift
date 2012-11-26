//
//  query_priv.h
//  TightDB
//

#import <Foundation/Foundation.h>

#pragma mark - Private Query interface

@interface Group()
+(Group *)groupTightdbGroup:(tightdb::Group *)tightdbGroup readOnly:(BOOL)readOnly;
-(void)clearGroup;
@end
