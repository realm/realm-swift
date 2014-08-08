//
//  RLMBoolTableCellView.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 06/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RLMTableCellView.h"

@interface RLMBoolTableCellView : RLMTableCellView

@property(strong) IBOutlet NSButton *checkBox;

@end
