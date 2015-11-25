//
//  RLMResultsBase.h
//  Realm
//
//  Created by Adam Fish on 11/25/15.
//  Copyright © 2015 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLMResults;

// A base class for Swift generic Results to make it possible to interact with
// them from obj-c
@interface RLMResultsBase : NSObject <NSFastEnumeration>

@property (nonatomic, strong) RLMResults *rlmResults;

- (instancetype)initWithResults:(RLMResults *)rlmResults;

@end
