//
//  RLMObject+Schema.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 09/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Realm/Realm.h>


@interface RLMObject (Schema)

- (RLMObjectSchema *)resolvedSchema;

@end
