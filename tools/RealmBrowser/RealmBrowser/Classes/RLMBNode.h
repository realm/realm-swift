//
//  RLMBNode.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface RLMBNode : NSObject

@property (nonatomic) RLMRealm *realm;
@property (nonatomic) RLMObjectSchema *objectSchema;

@property (nonatomic) NSUInteger instanceCount;

-(RLMObject *)instanceAtIndex:(NSUInteger)index;

@end


@interface RLMBRootNode : RLMBNode

@end


@interface RLMBArrayNode : RLMBNode

@end


@interface RLMBResultsNode : RLMBNode

@end


@interface RLMBObjectNode : RLMBNode

@end
