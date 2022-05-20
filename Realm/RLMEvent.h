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

#import <Foundation/Foundation.h>
#import <Realm/RLMConstants.h>

#ifdef __cplusplus
#include <memory>

namespace realm {
struct AuditConfig;
}
#endif

NS_ASSUME_NONNULL_BEGIN

@class RLMRealm, RLMUser, RLMRealmConfiguration;
typedef RLM_CLOSED_ENUM(NSUInteger, RLMSyncLogLevel);

struct RLMEventContext;
typedef void (^RLMEventCompletion)(NSError *);

FOUNDATION_EXTERN struct RLMEventContext *_Nullable RLMEventGetContext(RLMRealm *realm);
FOUNDATION_EXTERN void RLMEventBeginScope(struct RLMEventContext *context, NSString *activity);
FOUNDATION_EXTERN void RLMEventEndScope(struct RLMEventContext *context, RLMEventCompletion _Nullable completion);
FOUNDATION_EXTERN void RLMEventRecordEvent(struct RLMEventContext *context, NSString *activity,
                                           NSString *_Nullable event, NSString *_Nullable data,
                                           RLMEventCompletion _Nullable completion);
FOUNDATION_EXTERN void RLMEventUpdateMetadata(struct RLMEventContext *context,
                                              NSDictionary<NSString *, NSString *> *newMetadata);

@interface RLMEventConfiguration : NSObject
@property (nonatomic) NSString *partitionPrefix;
@property (nonatomic, nullable) RLMUser *syncUser;
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *metadata;
@property (nonatomic, nullable) void (^logger)(RLMSyncLogLevel, NSString *);
@property (nonatomic, nullable) void (^errorHandler)(NSError *);

#ifdef __cplusplus
- (std::shared_ptr<realm::AuditConfig>)auditConfigWithRealmConfiguration:(RLMRealmConfiguration *)realmConfig;
#endif
@end

NS_ASSUME_NONNULL_END
