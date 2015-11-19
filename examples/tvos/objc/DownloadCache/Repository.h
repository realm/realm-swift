//
//  Repository.h
//  RealmExamples
//
//  Created by Katsumi Kishikawa on 11/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

#import <Realm/Realm.h>

@interface Repository : RLMObject

@property NSString *identifier;
@property NSString *name;
@property NSString *avatarURL;

@end
