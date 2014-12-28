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

#import <Foundation/Foundation.h>

typedef id (^RLMTransformBlock)(id object);

/**
 * This class provides a wrapper transforming an input using one of multiple
 * transform options, such as a block or date formatter.
 * Objects are created using the convenience methods below:
 * @see transformerWithDateFormatter:
 * @see transformerWithBlock:
 */
@interface RLMTransformer : NSObject

/**
 * @property dateFormatter
 * @brief The NSDateFormatter set when the transformer was created and applied
 * to the input of transformObject:.
 */
@property(nonatomic, copy, readonly) NSDateFormatter *dateFormatter;

/**
 * @property transformBlock
 * @brief The transform block set when the transformer was created and applied
 * to the input of transformObject:. The value is of type RLMTransformBlock
 */
@property(nonatomic, copy, readonly) RLMTransformBlock transformBlock;

/**
 * @brief Applies the transform set for this object to the input and returns
 * the resulting object.
 
 * @param object    The object that should be transformed.
 * @return The transformed object.
 */
- (id)transformObject:(id)object;

/**
 * @brief Creates a date formatter based RLMTransformer object ready to use.
 
 * @param formatter The date formatter that should be applied during transformation.
 * @return An instance of RLMTransformer ready for use.
 
 * @see transformObject:
 */
+ (RLMTransformer *)transformerWithDateFormatter:(NSDateFormatter *)formatter;

/**
 * @brief Creates a block based RLMTransformer object ready to use.
 
 * @param block The block that should be executed during transformation.
 * @return  An instance of RLMTransformer ready for use.
 
 * @see transformObject:
 */
+ (RLMTransformer *)transformerWithBlock:(RLMTransformBlock)block;

@end
