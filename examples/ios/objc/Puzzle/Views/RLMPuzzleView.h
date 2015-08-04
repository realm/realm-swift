////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RLMPuzzlePieceIdentifier) {
    RLMPuzzlePieceIdentifierA1,
    RLMPuzzlePieceIdentifierA2,
    RLMPuzzlePieceIdentifierA3,
    RLMPuzzlePieceIdentifierA4,
    RLMPuzzlePieceIdentifierA5,
    RLMPuzzlePieceIdentifierB1,
    RLMPuzzlePieceIdentifierB2,
    RLMPuzzlePieceIdentifierB3,
    RLMPuzzlePieceIdentifierB4,
    RLMPuzzlePieceIdentifierB5,
    RLMPuzzlePieceIdentifierC1,
    RLMPuzzlePieceIdentifierC2,
    RLMPuzzlePieceIdentifierC3,
    RLMPuzzlePieceIdentifierC4,
    RLMPuzzlePieceIdentifierC5,
    RLMPuzzlePieceIdentifierD1,
    RLMPuzzlePieceIdentifierD2,
    RLMPuzzlePieceIdentifierD3,
    RLMPuzzlePieceIdentifierD4,
    RLMPuzzlePieceIdentifierD5,
    RLMPuzzlePieceIdentifierNum
};

@class RLMPuzzleView;

@protocol RLMPuzzleViewDelegate <NSObject>

- (void)puzzleView:(RLMPuzzleView *)puzzleView pieceMoved:(RLMPuzzlePieceIdentifier)piece toPoint:(CGPoint)point;

@end

@interface RLMPuzzleView : UIView

@property (nonatomic, readonly) NSInteger numberOfPieces;
@property (nonatomic, weak) id<RLMPuzzleViewDelegate> delegate;

- (void)movePiece:(RLMPuzzlePieceIdentifier)piece toPoint:(CGPoint)point animated:(BOOL)animated;
- (void)scramblePiecesAnimated;

@end
