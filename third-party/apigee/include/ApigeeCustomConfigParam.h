//
//  ApigeeCustomConfigParam.h
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @abstract A custom configuration parameter
 */
@interface ApigeeCustomConfigParam : NSObject

@property (assign, nonatomic) NSInteger paramId;

/*!
 @property category The property category
 */
@property (strong, nonatomic) NSString *category;

/*!
 @property key The property key
 */
@property (strong, nonatomic) NSString *key;

/*!
 @property value The property value
 */
@property (strong, nonatomic) NSString *value;

@end
