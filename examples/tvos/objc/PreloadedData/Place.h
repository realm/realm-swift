//
//  Place.h
//  RealmExamples
//
//  Created by Katsumi Kishikawa on 11/20/15.
//  Copyright © 2015 Realm. All rights reserved.
//

#import <Realm/Realm.h>

@interface Place : RLMObject

@property NSString *postalCode;
@property NSString *placeName;
@property NSString *state;
@property NSString *stateAbbreviation;
@property NSString *county;
@property double latitude;
@property double longitude;

@end
