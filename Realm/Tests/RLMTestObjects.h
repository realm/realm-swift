//
//  RLMTestObjects.h
//  Realm
//
//  Created by Ari Lazier on 5/20/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLMObject.h"

@interface AllTypesObject : RLMObject
@property BOOL           boolCol;
@property int            intCol;
@property float          floatCol;
@property double         doubleCol;
@property NSString      *stringCol;
@property NSData        *binaryCol;
@property NSDate        *dateCol;
@property bool           cBoolCol;
@property long           longCol;
@property id             mixedCol;
//@property AgeTable      *tableCol;
@end

