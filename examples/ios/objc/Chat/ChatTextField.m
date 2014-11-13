//
//  ChatTextField.m
//  RealmExamples
//
//  Created by JP Simard on 11/12/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "ChatTextField.h"

@implementation ChatTextField

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 15.0, 0.0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds, 15.0, 0.0);
}

@end
