//
//  RLMTableColumn.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Realm.h"

@interface RLMTableColumn : NSObject

@property (nonatomic, readonly) NSString *columnName;
@property (nonatomic, readonly) RLMType columnType;
@property (nonatomic, readonly) Class columnClass;

- (instancetype)initWithName:(NSString *)name type:(RLMType)type;

@end
