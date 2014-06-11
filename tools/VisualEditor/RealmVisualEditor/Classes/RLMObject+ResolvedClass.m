//
//  RLMObject+Schema.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 09/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMObject+ResolvedClass.h"

static NSString *const RLMLinkedObjectPrefix = @"RLMReadOnly_";

@implementation RLMObject (Schema)

// This property is defined in the private files of the Realm ObjC binding.
@dynamic schema;

@end
