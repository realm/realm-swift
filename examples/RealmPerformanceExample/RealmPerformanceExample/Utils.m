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

#import "Utils.h"

@implementation Utils
{
    UIScrollView *_view;
    NSArray *_groups;
    float y;
}

#define LineHeight 31

-(id)initWithView:(UIScrollView *)view
{
    self = [super init];
    if (self) {
        _view = view;
        y = 0;
        NSArray *colors = [NSArray arrayWithObjects:[UIColor whiteColor], [UIColor yellowColor], [UIColor cyanColor], [UIColor greenColor], nil];
        _groups = [NSArray arrayWithObjects:[[UIView alloc] init], [[UIView alloc] init], [[UIView alloc] init], [[UIView alloc] init], nil];
        int idx = 0;
        for(UIView *v in _groups) {
            [_view addSubview:v];
            [v setBackgroundColor:[colors objectAtIndex:idx]];
            idx++;
        }
    }
    return self;
}


- (NSString *) pathForDataFile:(NSString *)filename {
    NSArray*    documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString*   path = nil;

    if (documentDir) {
        path = [documentDir objectAtIndex:0];
    }

    return [NSString stringWithFormat:@"%@/%@", path, filename];
}

-(void)Eval:(BOOL)good msg:(NSString *)msg
{
    [self OutGroup:GROUP_LOG msg:[NSString stringWithFormat:@"%@ - %@", good?@"OK":@"Fail", msg] good:good];
}

-(void)resizeParent
{
    float height = 0;
    for(UIView *view in _groups) {
        CGRect frame = view.frame;
        frame.origin.y = height;
        view.frame = frame;
        height += view.frame.size.height;
//        NSLog(@"View: %@", NSStringFromCGRect(frame));
    }
    _view.contentSize = CGSizeMake(_view.contentSize.width, height);
}
-(void)OutGroup:(int)group msg:(NSString *)msg
{
    [self OutGroup:group msg:msg good:YES];
}
-(void)OutGroup:(int)group msg:(NSString *)msg good:(BOOL)good
{
    UIView *view = [_groups objectAtIndex:group];
    CGRect frame = view.frame;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height, view.bounds.size.width, LineHeight)];
    [label setBackgroundColor:[UIColor clearColor]];
    label.text = msg;
    if (!good)
        label.backgroundColor = [UIColor redColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [view addSubview:label];
    frame.size.width = _view.bounds.size.width;
    frame.size.height += label.frame.size.height;
    view.frame = frame;
    [self resizeParent];
}


@end
