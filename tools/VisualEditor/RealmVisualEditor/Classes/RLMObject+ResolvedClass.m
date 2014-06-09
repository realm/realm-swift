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

- (RLMObjectSchema *)resolvedSchema
{
    // Get the realm and its schema where the instance is stored.
    RLMRealm *realm = self.realm;
    RLMSchema *schema = realm.schema;
    
    // Get the name of the instance's class
    NSString *className = NSStringFromClass([self class]);
    
    // This is a FIX: We need to premove a prefix added by the ObjC binding to the class name for
    // instances linked to from a link property.
    if ([className hasPrefix:RLMLinkedObjectPrefix]) {
        className = [className substringFromIndex:RLMLinkedObjectPrefix.length];
    }
    
    RLMObjectSchema *objectSchema = [schema schemaForObject:className];
    
    return objectSchema;
}

@end
