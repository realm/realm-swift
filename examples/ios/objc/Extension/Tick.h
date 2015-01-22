//
//  Tick.h
//  RealmExamples
//
//  Created by Samuel Giddins on 1/21/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <Realm/Realm.h>

@interface Tick : RLMObject

@property (nonatomic, strong) NSString *tickID;

@property (nonatomic, assign) NSInteger count;

@end
