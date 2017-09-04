//
//  RLMResults+RLMResults_Sync.h
//  Realm
//
//  Created by Adam Fish on 8/30/17.
//  Copyright © 2017 Realm. All rights reserved.
//

#import <Realm/Realm.h>
#import <Realm/RLMCollection.h>

NS_ASSUME_NONNULL_BEGIN

@class RLMObject, RLMRealm, RLMNotificationToken;

@interface RLMResults<RLMObjectType> (RLMResults_Sync)

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults<RLMObjectType> *__nullable results,
                                                         RLMCollectionChange *__nullable change,
                                                         NSError *__nullable error))block __attribute__((warn_unused_result));

@end

NS_ASSUME_NONNULL_END
