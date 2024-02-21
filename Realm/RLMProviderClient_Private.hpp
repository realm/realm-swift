////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import <Realm/RLMProviderClient.h>

#import <realm/object-store/sync/app.hpp>

@interface RLMProviderClient () {
    @public
    std::shared_ptr<realm::app::App> _app;
}
- (instancetype _Nonnull)initWithApp:(std::shared_ptr<realm::app::App>)app;

/// A block type used to report an error
typedef void(^RLMProviderClientOptionalErrorBlock)(NSError * _Nullable);

realm::util::UniqueFunction<void(std::optional<realm::app::AppError>)>
RLMWrapCompletion(_Nonnull RLMProviderClientOptionalErrorBlock);
@end
