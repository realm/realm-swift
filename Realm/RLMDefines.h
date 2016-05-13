////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

@class RLMObject;

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#pragma mark - Generics

#if __has_extension(objc_generics)
#define RLM_GENERIC(...) <__VA_ARGS__>
#define RLM_GENERIC_COLLECTION <RLMObjectType: RLMObject *>
#define RLM_GENERIC_RETURN <RLMObjectType>
#define RLMObjectArgument RLMObjectType
#else
#define RLM_GENERIC(...)
#define RLM_GENERIC_COLLECTION
#define RLM_GENERIC_RETURN
typedef id RLMObjectType;
typedef RLMObject * RLMObjectArgument;
#endif

#pragma mark - Swift Availability

#if defined(NS_SWIFT_UNAVAILABLE)
#  define RLM_SWIFT_UNAVAILABLE(msg) NS_SWIFT_UNAVAILABLE(msg)
#else
#  define RLM_SWIFT_UNAVAILABLE(msg)
#endif
