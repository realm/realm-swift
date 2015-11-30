//
//  RLMResultsBase.m
//  Realm
//
//  Created by Adam Fish on 11/25/15.
//  Copyright © 2015 Realm. All rights reserved.
//

#import "RLMResultsBase.h"
#import "RLMResults.h"

@implementation RLMResultsBase

- (instancetype)initWithResults:(RLMResults *)rlmResults {
    self = [super init];
    if (self) {
        _rlmResults = rlmResults;
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    return [_rlmResults valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    [_rlmResults setValue:value forKey:key];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    return [_rlmResults countByEnumeratingWithState:state objects:buffer count:len];
}

@end
