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

#import <Realm/RLMDefines.h>

RLM_ASSUME_NONNULL_BEGIN

@class RLMRealm, RLMResults, RLMObject;

@protocol RLMCollection <NSFastEnumeration>

@required

@property (nonatomic, readonly, assign) NSUInteger count;
@property (nonatomic, readonly, copy) NSString *objectClassName;
@property (nonatomic, readonly) RLMRealm *realm;

- (id)objectAtIndex:(NSUInteger)index;
- (nullable id)firstObject;
- (nullable id)lastObject;
- (NSUInteger)indexOfObject:(RLMObject *)object;
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...;
- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate;
- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ...;
- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate;
- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending;
- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties;
- (id)objectAtIndexedSubscript:(NSUInteger)index;

/**
 Returns an NSArray containing the results of invoking `valueForKey:` using key on each of the collection's objects.

 @param key The name of the property.

 @return NSArray containing the results of invoking `valueForKey:` using key on each of the collection's objects.
 */
- (nullable id)valueForKey:(NSString *)key;

/**
 Invokes `setValue:forKey:` on each of the collection's objects using the specified value and key.

 @warning This method can only be called during a write transaction.

 @param value The object value.
 @param key   The name of the property.
 */
- (void)setValue:(nullable id)value forKey:(NSString *)key;

@end

RLM_ASSUME_NONNULL_END
