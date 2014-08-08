//
//  RLMBadgeTableCellView.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 05/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RLMTableCellView.h"

@interface RLMBadgeTableCellView : RLMTableCellView

@property (strong) IBOutlet NSButton *badge;

@end
