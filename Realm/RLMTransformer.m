////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

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
