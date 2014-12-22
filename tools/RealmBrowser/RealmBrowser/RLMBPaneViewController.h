////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>
#import <Realm/Realm.h>
#import "RLMBTextField.h"

@class RLMBPaneViewController;
@protocol RLMBCanvasDelegate <NSObject>

- (void)addPaneWithArray:(RLMArray *)array afterPane:(RLMBPaneViewController *)pane;
- (void)addPaneWithObject:(RLMObject *)object afterPane:(RLMBPaneViewController *)pane;

@end


@protocol RLMBRealmDelegate <NSObject>

- (void)setProperty:(NSString *)propertyName ofObject:(RLMObject *)object toValue:(id)value;
- (void)deleteObjects:(NSArray *)objects;
- (void)removeObjectsAtIndices:(NSIndexSet *)rowIndices fromArray:(RLMArray *)array;

@end


@interface RLMBPaneViewController : NSViewController

@property (weak, nonatomic) id<RLMBCanvasDelegate> canvasDelegate;
@property (weak, nonatomic) id<RLMBRealmDelegate> realmDelegate;

@property (nonatomic) NSLayoutConstraint *widthConstraint;
@property (nonatomic, readonly) BOOL isWide;
@property (nonatomic, readonly) BOOL isRootPane;
@property (nonatomic, readonly) BOOL isArrayPane;
@property (nonatomic, readonly) BOOL isObjectPane;

@property (nonatomic) id<RLMCollection> objects;

- (void)updateWithObjects:(id<RLMCollection>)objects objectSchema:(RLMObjectSchema *)objectSchema;
- (void)minusRows:(NSIndexSet *)rowIndexes;

@end
