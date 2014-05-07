////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

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
