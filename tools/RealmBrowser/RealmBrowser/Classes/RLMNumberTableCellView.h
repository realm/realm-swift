//
//  RLMNumberTableCellView.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 07/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RLMNumberTextField : NSTextField

@property (nonatomic) NSNumber *number;

@end


@interface RLMNumberTableCellView : NSTableCellView

@end
