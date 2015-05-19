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

typedef NS_ENUM(NSInteger, RLMPuzzlePieceName) {
    RLMPuzzlePieceNameA1,
    RLMPuzzlePieceNameA2,
    RLMPuzzlePieceNameA3,
    RLMPuzzlePieceNameA4,
    RLMPuzzlePieceNameA5,
    RLMPuzzlePieceNameB1,
    RLMPuzzlePieceNameB2,
    RLMPuzzlePieceNameB3,
    RLMPuzzlePieceNameB4,
    RLMPuzzlePieceNameB5,
    RLMPuzzlePieceNameC1,
    RLMPuzzlePieceNameC2,
    RLMPuzzlePieceNameC3,
    RLMPuzzlePieceNameC4,
    RLMPuzzlePieceNameC5,
    RLMPuzzlePieceNameD1,
    RLMPuzzlePieceNameD2,
    RLMPuzzlePieceNameD3,
    RLMPuzzlePieceNameD4,
    RLMPuzzlePieceNameD5,
    RLMPuzzlePieceNameNum
};

@class RLMPuzzleView;

@protocol RLMPuzzleViewDelegate <NSObject>

- (void)puzzleView:(RLMPuzzleView *)puzzleView pieceMoved:(RLMPuzzlePieceName)piece toPoint:(CGPoint)point;

@end

@interface RLMPuzzleView : UIView

@property (nonatomic, readonly) NSInteger numberOfPieces;
@property (nonatomic, weak) id<RLMPuzzleViewDelegate> delegate;

- (void)movePiece:(RLMPuzzlePieceName)piece toPoint:(CGPoint)point animated:(BOOL)animated;
- (void)scramblePiecesAnimated;

@end
