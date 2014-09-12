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

#import "RLMArray.h"
#import "RLMObject.h"

@interface RLMRealm (Swift)
+ (void)clearRealmCache;
@end

@interface RLMArray (Swift)

- (instancetype)initWithObjectClassName:(NSString *)objectClassName;

- (NSUInteger)indexOfObjectWhere:(NSString *)predicateFormat args:(va_list)args;
- (RLMArray *)objectsWhere:(NSString *)predicateFormat args:(va_list)args;

@end

@interface RLMObject (Swift)

+ (RLMArray *)objectsWhere:(NSString *)predicateFormat args:(va_list)args;
+ (RLMArray *)objectsInRealm:(RLMRealm *)realm where:(NSString *)predicateFormat args:(va_list)args;

@end
