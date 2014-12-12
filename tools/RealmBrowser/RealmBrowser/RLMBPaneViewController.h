//
//  RLMBPaneViewController.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Realm/Realm.h>
#import "RLMBViewModel.h" // FIXME: inheritance/exposing

@class RLMBPaneViewController;
@protocol RLMBCanvasDelegate <NSObject>

- (void)addPaneWithArray:(RLMArray *)array afterPane:(RLMBPaneViewController *)pane;

@end


@protocol RLMBRealmDelegate <NSObject>

- (void)changeProperty:(NSString *)propertyName ofObject:(RLMObject *)object toValue:(id)value;

@end


@interface RLMBPaneViewController : NSViewController <NSTextFieldDelegate>

@property (weak, nonatomic) id<RLMBCanvasDelegate> canvasDelegate;
@property (weak, nonatomic) id<RLMBRealmDelegate> realmDelegate;

@property (nonatomic) NSLayoutConstraint *widthConstraint;
@property (nonatomic, readonly) BOOL isWide;

@property (nonatomic) id<RLMCollection> objects;

- (void)updateWithObjects:(id<RLMCollection>)objects objectSchema:(RLMObjectSchema *)objectSchema;

@end
