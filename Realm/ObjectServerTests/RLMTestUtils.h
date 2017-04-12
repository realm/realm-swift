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

void RLMSwapOutClassMethod(id classObject, SEL original, SEL swizzled);
void RLMSwapOutInstanceMethod(id classObject, SEL original, SEL swizzled);

#ifndef CUSTOM_REALM_URL
#define CUSTOM_REALM_URL(realm_identifier) \
[NSURL URLWithString:[NSString stringWithFormat:@"realm://localhost:9080/~/%@%@", NSStringFromSelector(_cmd), realm_identifier]]
#define REALM_URL() CUSTOM_REALM_URL(@"")
#endif
