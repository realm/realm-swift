//
//  ObjCModel.h
//  RealmSwiftExample
//
//  Created by JP Simard on 6/10/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

@import Realm;

@interface ObjCModel : RLMObject

@property NSString *name;
@property NSDate   *date;

@end
