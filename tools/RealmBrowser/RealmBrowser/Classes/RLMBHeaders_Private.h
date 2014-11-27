//
//  RLMBHeaders_Private.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 27/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#ifndef RealmBrowser_RLMBHeaders_Private_h
#define RealmBrowser_RLMBHeaders_Private_h

@interface RLMRealm ()
- (RLMResults *)allObjects:(NSString *)className;
- (RLMObject *)createObject:(NSString *)className withObject:(id)object;
@end

#endif
