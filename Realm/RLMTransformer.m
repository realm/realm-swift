//
//  RLMTransformer.m
//  Realm
//
//  Created by Nathan Jones on 12/23/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTransformer.h"

@interface RLMTransformer ()

@property(nonatomic, copy, readwrite) NSDateFormatter *dateFormatter;
@property(nonatomic, copy, readwrite) RLMTransformBlock transformBlock;

@end

@implementation RLMTransformer

- (id)transformObject:(id)object {
    if (self.dateFormatter) {
        return [self.dateFormatter dateFromString:object];
    
    } else if (self.transformBlock) {
        return self.transformBlock(object);
    
    }
    
    return nil;
}

+ (RLMTransformer *)transformerWithDateFormatter:(NSDateFormatter *)formatter {
    RLMTransformer *transform = [RLMTransformer new];
    transform.dateFormatter = formatter;
    
    return transform;
}

+ (RLMTransformer *)transformerWithBlock:(RLMTransformBlock)block {
    RLMTransformer *transform = [RLMTransformer new];
    transform.transformBlock = block;
    
    return transform;
}

@end
