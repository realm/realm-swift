//
//  Utils.h
//  TightDbExample
//
//  Created by Bjarne Christiansen on 5/24/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

-(id)initWithView:(UIScrollView *)view;

- (NSString *) pathForDataFile:(NSString *)filename;

-(void)Eval:(BOOL)good msg:(NSString *)msg;
@end
