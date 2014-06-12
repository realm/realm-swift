//
//  RLMRealmNode.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RLMClazzNode.h"

#import "RLMRealmOutlineNode.h"

@interface RLMRealmNode : NSObject <RLMRealmOutlineNode>

@property (nonatomic, readonly) RLMRealm *realm;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSArray *topLevelClazzes;

- (instancetype)initWithName:(NSString *)name url:(NSString *)url;

- (BOOL)connect:(NSError **)error;

- (void)addTable:(RLMClazzNode *)table;

@end
