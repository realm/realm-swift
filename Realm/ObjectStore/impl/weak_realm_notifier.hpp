////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#ifndef REALM_WEAK_REALM_NOTIFIER_HPP
#define REALM_WEAK_REALM_NOTIFIER_HPP

#include <realm/util/features.h>

#if REALM_PLATFORM_NODE
#include "impl/node/weak_realm_notifier.hpp"
#elif REALM_PLATFORM_APPLE
#include "impl/apple/weak_realm_notifier.hpp"
#elif REALM_ANDROID
#include "impl/android/weak_realm_notifier.hpp"
#else
#include "impl/generic/weak_realm_notifier.hpp"
#endif

#endif // REALM_WEAK_REALM_NOTIFIER_HPP
