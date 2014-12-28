//
//  RLMTransformer.h
//  Realm
//
//  Created by Nathan Jones on 12/23/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

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
