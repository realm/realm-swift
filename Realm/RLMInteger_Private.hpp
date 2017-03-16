////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMInteger.h"

#import <realm/link_view.hpp>
#import <realm/row.hpp>

@class RLMRealm;

/**
 Private implementation subclass of RLMInteger representing a Realm integer
 object attached to a row of the underlying database.
 */
@interface RLMIntegerView : RLMInteger

- (instancetype)initWithRow:(realm::Row)row columnIndex:(size_t)colIndex realm:(RLMRealm *)realm;

@end

/**
 Private implementation subclass of RLMNullableInteger representing a Realm
 nullable integer object attached to a row of the underlying database.
 */
@interface RLMNullableIntegerView : RLMNullableInteger

- (instancetype)initWithRow:(realm::Row)row columnIndex:(size_t)colIndex realm:(RLMRealm *)realm;

@end
