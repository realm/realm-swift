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

#import "RLMUUID.h"

@implementation NSUUID (RLMUUIDSupport)

- (instancetype)initWithRealmUuid:(realm::UUID)rUuid {
    if (self = [self initWithUUIDBytes: rUuid.to_bytes().data()]) {
//    if (self = [self initWithUUIDString:rUuid.to_string()]) {
        return self;
    }
    return nil;
}

- (realm::UUID)uuidValue {
    return realm::UUID([self.UUIDString cStringUsingEncoding: NSUTF8StringEncoding]);
}

@end
