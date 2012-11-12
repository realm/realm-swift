//
//  Utils.h
//  TightDbExample
//
//  Created by Bjarne Christiansen on 5/24/12.
//

#import <Foundation/Foundation.h>


#define GROUP_LOG 0
#define GROUP_RUN 1
#define GROUP_DIFF 2
#define GROUP_SIZE 3

@interface Utils : NSObject

-(id)initWithView:(UIScrollView *)view;

- (NSString *) pathForDataFile:(NSString *)filename;

-(void)Eval:(BOOL)good msg:(NSString *)msg;
-(void)OutGroup:(int)group msg:(NSString *)msg;
@end
