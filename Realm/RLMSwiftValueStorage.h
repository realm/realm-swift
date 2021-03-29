////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

NS_ASSUME_NONNULL_BEGIN

@class RLMObjectBase, RLMProperty;
@protocol RLMValue;

/// This class implements the backing storage for `RealmProperty<>`. It is not intended that this class be
/// subclassed or used directly.
// RLMSwiftValueStorage
@interface RLMSwiftValueStorage : NSObject

@property (nonatomic, nullable) id value NS_REFINED_FOR_SWIFT;

/// Hands over the backing storage to managed accessors.
/// @param parent The enclosing parent Realm Object of this class.
/// @param property The property on the Realm Object that represents this class.
- (void)attachWithParent:(RLMObjectBase *)parent
                property:(RLMProperty *)property;

@end

NS_ASSUME_NONNULL_END
