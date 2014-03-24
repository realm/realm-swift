//
//  ApigeeUIWebView.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @class ApigeeUIWebView
 @abstract UIWebView with built-in network performance capture
 @discussion Note that HTTP status codes are not reported for calls made from
    this class because they're not accessible from UIWebView.
 */
@interface ApigeeUIWebView : UIWebView

/*!
 @abstract Initialization for NSCoding
 @param aDecoder an NSCoder instance for data population
 */
- (id) initWithCoder:(NSCoder *)aDecoder;

/*!
 @abstract Initialization with frame rectangle
 @param frame the rectangle frame for initial size and placement
 */
- (id) initWithFrame:(CGRect)frame;

/*!
 @abstract Sets the delegate for event callbacks
 @param delegate the UIWebViewDelegate to use for event callbacks
 */
- (void) setDelegate:(id<UIWebViewDelegate>)delegate;

@end
