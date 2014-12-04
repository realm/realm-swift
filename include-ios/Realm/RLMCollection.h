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

@class RLMResults, RLMObject;

@protocol RLMCollection <NSFastEnumeration>

@required

- (id)objectAtIndex:(NSUInteger)index;
- (id)firstObject;
- (id)lastObject;
- (NSUInteger)indexOfObject:(RLMObject *)object;
- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat, ...;
- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate;
- (RLMResults *)objectsWhere:(NSString *)predicateFormat, ...;
- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate;
- (RLMResults *)sortedResultsUsingProperty:(NSString *)property ascending:(BOOL)ascending;
- (RLMResults *)sortedResultsUsingDescriptors:(NSArray *)properties;
- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end