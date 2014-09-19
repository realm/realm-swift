//
//  RLMModelViewerWindowController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 19/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMModelViewerWindowController.h"

@interface RLMModelViewerWindowController ()

@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation RLMModelViewerWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.textView.string = self.modelText;
    self.window.title = self.windowTitle;
}

@end
