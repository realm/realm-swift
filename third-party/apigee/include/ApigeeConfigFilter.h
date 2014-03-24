//
//  ApigeeConfigFilter.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//


@interface ApigeeConfigFilter : NSObject

@property (assign, nonatomic) NSInteger filterId;
@property (strong, nonatomic) NSString *filterType;
@property (strong, nonatomic) NSString *filterValue;

@end
