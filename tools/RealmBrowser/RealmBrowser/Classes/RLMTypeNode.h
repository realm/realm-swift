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
#import <Realm/Realm.h>

#import "RLMRealmOutlineNode.h"
#import "RLMClassProperty.h"

@interface RLMTypeNode : NSObject <RLMRealmOutlineNode>

@property (nonatomic, readonly) RLMRealm *realm;
@property (nonatomic, readonly) RLMObjectSchema *schema;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *propertyColumns;
@property (nonatomic, readonly) NSUInteger instanceCount;

- (instancetype)initWithSchema:(RLMObjectSchema *)schema inRealm:(RLMRealm *)realm;

- (id)minimumOfPropertyNamed:(NSString *)propertyName;

- (NSNumber *)averageOfPropertyNamed:(NSString *)propertyName;

- (id)maximumOfPropertyNamed:(NSString *)propertyName;

- (NSNumber *)sumOfPropertyNamed:(NSString *)propertyName;

- (RLMObject *)instanceAtIndex:(NSUInteger)index;

- (NSUInteger)indexOfInstance:(RLMObject *)instance;

@end
