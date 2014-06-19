//
//  RLMClazzProperty.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface RLMClazzProperty : NSObject

@property (nonatomic, readonly) RLMProperty *property;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) RLMPropertyType type;
@property (nonatomic, readonly) Class clazz;

- (instancetype)initWithProperty:(RLMProperty *)property;

@end
