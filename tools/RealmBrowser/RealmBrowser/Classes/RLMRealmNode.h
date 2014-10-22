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

#import "RLMClassNode.h"

#import "RLMRealmOutlineNode.h"

@interface RLMRealm ()

+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                     inMemory:(BOOL)inMemory
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError;

- (RLMResults *)allObjects:(NSString *)className;

@end

@interface RLMRealmNode : NSObject <RLMRealmOutlineNode>

@property (nonatomic, readonly) RLMRealm *realm;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSArray *topLevelClasses;

- (instancetype)initWithName:(NSString *)name url:(NSString *)url;

- (BOOL)connect:(NSError **)error;

- (void)addTable:(RLMClassNode *)table;

@end
