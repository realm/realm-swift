////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import <Realm/RLMError.h>

#import <realm/exceptions.hpp>
#import <realm/status_with.hpp>

RLM_HIDDEN_BEGIN

namespace realm {
struct SyncError;
namespace app {
struct AppError;
}
}

NSError *makeError(realm::Status const& status);

template <typename T>
NSError *makeError(realm::StatusWith<T> const& statusWith) {
    return makeError(statusWith.get_status());
}

NSError *makeError(realm::Exception const& exception);
NSError *makeError(realm::FileAccessError const& exception);
NSError *makeError(std::exception const& exception);
NSError *makeError(std::system_error const& exception);
NSError *makeError(realm::app::AppError const& error);
NSError *makeError(realm::SyncError&& error);
NSError *makeError(realm::SyncError const& error) = delete;

RLM_HIDDEN_END
