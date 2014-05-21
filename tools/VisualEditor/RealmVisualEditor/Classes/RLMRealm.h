//
//  RLMRealm.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RLMRealmTable.h"

#import "RLMRealmOutlineNode.h"

@interface RLMRealm : NSObject <RLMRealmOutlineNode>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSArray *topLevelTables;

- (instancetype)initWithName:(NSString *)name url:(NSString *)url;

- (void)addTable:(RLMRealmTable *)table;

@end
