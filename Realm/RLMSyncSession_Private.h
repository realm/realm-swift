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

#import "RLMSyncSession.h"

@class RLMSyncSessionDataModel;

@interface RLMSyncSession ()

@property (nonatomic, readwrite) NSString *localIdentifier;

/**
 Given a newly-created session object, configure all fields which are not expected to change between requests (except
 for `path`, which is configured by the sync manager when it retrieves the object from its dictionary. Also sets the
 validity flag to YES.

 This method should only be called once.
 */
- (void)configureWithAuthServerURL:(NSURL *)authServer
                        remotePath:(RLMSyncRealmPath)path
                  sessionDataModel:(RLMSyncSessionDataModel *)model;

- (instancetype)initPrivate NS_DESIGNATED_INITIALIZER;

@end
