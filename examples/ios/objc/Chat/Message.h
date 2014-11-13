//
//  Message.h
//  RealmExamples
//
//  Created by JP Simard on 11/12/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <Realm/Realm.h>

@interface Message : RLMObject
@property NSDate *timestamp;
@property NSString *content;
@property NSString *sender;
@end
