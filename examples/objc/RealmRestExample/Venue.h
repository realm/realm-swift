//
//  Venue.h
//  RealmRestExample
//
//  Created by Alex on 7/5/14.
//  Copyright (c) 2014 Realm Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface Venue : RLMObject
@property NSString * foursquareID;
@property NSString * name;
@end
