//
//  RLMTable+Predicates.h
//  Realm
//
//  Created by JP Simard on 5/2/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTable.h"

@class RLMView;

@interface RLMTable (Predicates)

/**---------------------------------------------------------------------------------------
 *  @name Querying a Table
 *  ---------------------------------------------------------------------------------------
 */
/**
 Returns the **first** object matching the [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html)
 
 RLMRow *r = [table find:@"name == \"name10\""];
 
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
 r = [table find:predicate];
 
 @param condition An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the NSString instead of the NSPredicate.
 
 @return The **first** object matching the Predicate. It will be of the same type as the RLMRow subclass used on this RLMTable
 @see where:
 */
- (id)find:(id)condition;
/**
 Returns **all** objects matching the [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html).
 
 RLMView *v = [table where:@"name == \"name10\""];
 
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
 v = [table where:predicate];
 
 @param condition An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the NSString instead of the NSPredicate.
 
 @return A reference to an RLMView containing **all** objects matching the Predicate. Objects contained will be of the same type as the RLMRow subclass used on this RLMTable
 @see find:
 @see where:orderBy:
 */
- (RLMView *)where:(id)condition;
/**
 Returns **all** objects matching the [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html), in the order specified by the [NSSortDescriptor](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/NSSortDescriptor_Class/Reference/Reference.html).
 
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age = %@", @3];
 NSSortDescriptor * reverseSort = [NSSortDescriptor sortDescriptorWithKey:@"age" ascending:NO];
 v = [table where:predicate oderBy:reverseSort];
 
 v = [table where:predicate orderBy:@"age"];
 
 @param condition An [NSPredicate](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSPredicate_Class/Reference/NSPredicate.html). You can also use the NSString instead of the NSPredicate.
 
 @param order     An [NSSortDescriptor](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/NSSortDescriptor_Class/Reference/Reference.html). You can also use the NSString instead of the NSSortDescriptor.
 
 @return A reference to an RLMView containing **all** objects matching the Predicate, sorted according to the Sort Descriptor. Objects contained will be of the same type as the RLMRow subclass used on this RLMTable
 
 @see where:
 */
- (RLMView *)where:(id)condition orderBy:(id)order;

@end
