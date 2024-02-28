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

#import "RLMUser+ObjectServerTests.h"

#import "RLMSyncSession_Private.hpp"
#import "RLMRealmUtil.hpp"

#import <realm/object-store/sync/sync_session.hpp>
#import <realm/sync/client_base.hpp>
#import <realm/sync/protocol.hpp>

using namespace realm;

@implementation RLMUser (ObjectServerTests)

- (void)simulateClientResetErrorForSession:(NSString *)partitionValue {
    RLMSyncSession *session = [self sessionForPartitionValue:partitionValue];
    NSAssert(session, @"Cannot call with invalid URL");

    std::shared_ptr<SyncSession> raw_session = session->_session.lock();
    realm::sync::SessionErrorInfo error = {{realm::ErrorCodes::BadChangeset, "Not a real error message"}, true};
    error.server_requests_action = realm::sync::ProtocolErrorInfo::Action::ClientReset;
    SyncSession::OnlyForTesting::handle_error(*raw_session, std::move(error));
}

@end
