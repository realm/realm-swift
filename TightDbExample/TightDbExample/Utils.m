//
//  Utils.m
//  TightDbExample
//
//  Created by Bjarne Christiansen on 5/24/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "Utils.h"

@implementation Utils
{
    UIScrollView *_view;
    float y;
}

#define LineHeight 31

-(id)initWithView:(UIScrollView *)view
{
    self = [super init];
    if (self) {
        _view = view;
        y = 0;
    }
    return self;
}


- (NSString *) pathForDataFile:(NSString *)filename {
    NSArray*	documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*	path = nil;
 	
    if (documentDir) {
        path = [documentDir objectAtIndex:0];    
    }
 	
    return [NSString stringWithFormat:@"%@/%@", path, filename];
}

-(void)Eval:(BOOL)good msg:(NSString *)msg
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, y, _view.bounds.size.width, LineHeight)];
    label.text = [NSString stringWithFormat:@"%@ - %@", good?@"OK":@"Fail", msg];
    if (!good)
        label.backgroundColor = [UIColor redColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_view addSubview:label];
    y += LineHeight;
    _view.contentSize = CGSizeMake(_view.bounds.size.width, y);
}


@end
