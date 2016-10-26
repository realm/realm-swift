////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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
#import "RLMPuzzleView.h"
#import "RLMPuzzlePieceView.h"

@interface RLMPuzzleView ()

@property (nonatomic, strong) NSArray *puzzlePieces;
@property (nonatomic, strong) NSString *pieceNames; //String versions of the piece names
@property (nonatomic, strong) NSDictionary *pieceDefaultLocations; //The CGPoints for each piece in default space
@property (nonatomic, assign) CGPoint gestureOrigin;
@property (nonatomic, assign) CGPoint gesturePieceOrigin;
@property (nonatomic, weak)   UIView *draggingView;

- (void)setupPuzzlePieces;
- (CGPoint)pointForPiece:(RLMPuzzlePieceIdentifier)piece;
- (void)layoutPiecesInOriginalPlaces;
- (void)gestureRecognized:(UIPanGestureRecognizer *)gestureRecognizer;

@end

@implementation RLMPuzzleView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    }
        
    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self setupPuzzlePieces];
    [self layoutPiecesInOriginalPlaces];
}

- (void)setupPuzzlePieces
{
    if (self.puzzlePieces)
        return;
    
    NSMutableArray *puzzlePieces = [NSMutableArray array];
    
    NSArray *verticalSlices = @[@"A", @"B", @"C", @"D"];
    NSArray *horizontalSlices = @[@"1", @"2", @"3", @"4"];
    
    NSInteger i = 0;
    for (NSString *verticalSlice in verticalSlices) {
        for (NSString *horizontalSlice in horizontalSlices) {
            NSString *name = [NSString stringWithFormat:@"%@%@", verticalSlice, horizontalSlice];
            RLMPuzzlePieceView *pieceView = [[RLMPuzzlePieceView alloc] initWithPieceName:name];
            pieceView.tag = i++;
            [puzzlePieces addObject:pieceView];
            
            [self addSubview:pieceView];
        }
    }
    
    self.puzzlePieces = [NSArray arrayWithArray:puzzlePieces];
    
    for (RLMPuzzlePieceView *pieceView in self.puzzlePieces) {
        UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognized:)];
        [pieceView addGestureRecognizer:recognizer];
    }
}

- (CGPoint)pointForPiece:(RLMPuzzlePieceIdentifier)piece
{
    switch (piece) {
        case RLMPuzzlePieceIdentifierA1: return CGPointMake(0,0);
        case RLMPuzzlePieceIdentifierA2: return CGPointMake(190,0);
        case RLMPuzzlePieceIdentifierA3: return CGPointMake(313.5,0);
        case RLMPuzzlePieceIdentifierA4: return CGPointMake(573,0);
        case RLMPuzzlePieceIdentifierB1: return CGPointMake(0,121);
        case RLMPuzzlePieceIdentifierB2: return CGPointMake(122.5f,188.5f);
        case RLMPuzzlePieceIdentifierB3: return CGPointMake(381.5,120.5f);
        case RLMPuzzlePieceIdentifierB4: return CGPointMake(505,188.5f);
        case RLMPuzzlePieceIdentifierC1: return CGPointMake(0.0f,380.5f);
        case RLMPuzzlePieceIdentifierC2: return CGPointMake(189.5f,312.5f);
        case RLMPuzzlePieceIdentifierC3: return CGPointMake(314,381);
        case RLMPuzzlePieceIdentifierC4: return CGPointMake(573,313.5);
        case RLMPuzzlePieceIdentifierD1: return CGPointMake(0.0,505);
        case RLMPuzzlePieceIdentifierD2: return CGPointMake(122.5,575);
        case RLMPuzzlePieceIdentifierD3: return CGPointMake(382,505);
        case RLMPuzzlePieceIdentifierD4: return CGPointMake(506.5,573.5);
        default: break;
    }
    
    return CGPointZero;
}

- (void)layoutPiecesInOriginalPlaces
{
    NSInteger i = 0;
    for (RLMPuzzlePieceView *pieceView in self.puzzlePieces) {
        CGRect frame = pieceView.frame;
        frame.origin = [self pointForPiece:i++];
        pieceView.frame = frame;
    }
}

- (void)scramblePiecesAnimated
{
    CGRect frame = self.bounds;
    frame.origin.x -= 75.0f;
    frame.size.width += (75 * 2);
    
    //Work out the random placement before animating so the delegate can be informed at the same time
    NSMutableArray *points = [NSMutableArray array];
    for (NSInteger pieceIndex = RLMPuzzlePieceIdentifierA1; pieceIndex < RLMPuzzlePieceIdentifierNum; pieceIndex++) {
        CGPoint point = CGPointZero;
        point.x = frame.origin.x + arc4random_uniform(frame.size.width);
        point.y = frame.origin.y + arc4random_uniform(frame.size.height);
        [points addObject:[NSValue valueWithCGPoint:point]];
        
        if ([self.delegate respondsToSelector:@selector(puzzleView:pieceMoved:toPoint:)]) {
            [self.delegate puzzleView:self pieceMoved:pieceIndex toPoint:point];
        }
    }
    
    __block NSInteger i = 0;
    [UIView animateWithDuration:1.5f delay:1.5f usingSpringWithDamping:1.0f initialSpringVelocity:0.2f options:0 animations:^{
        for (RLMPuzzlePieceView *piece in self.puzzlePieces) {
            piece.center = [points[i++] CGPointValue];
        }
    } completion:nil];
}

- (void)movePiece:(RLMPuzzlePieceIdentifier)piece toPoint:(CGPoint)point animated:(BOOL)animated
{
    RLMPuzzlePieceView *pieceView = self.puzzlePieces[piece];
    if (pieceView == self.draggingView) {
        return;
    }
    
    if (animated == NO) {
        pieceView.center = point;
        return;
    }
    
    [UIView animateWithDuration:0.1f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.2f options:0 animations:^{
        pieceView.center = point;
    } completion:nil];
}

- (void)gestureRecognized:(UIPanGestureRecognizer *)gestureRecognizer
{
    RLMPuzzlePieceView *pieceView = (RLMPuzzlePieceView *)gestureRecognizer.view;
    CGPoint point = [gestureRecognizer locationInView:self];
    CGPoint piecePoint = pieceView.center;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.gestureOrigin = point;
        self.gesturePieceOrigin = piecePoint;
        self.draggingView = pieceView;
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.draggingView = nil;
    }
    
    point.x -= self.gestureOrigin.x;
    point.y -= self.gestureOrigin.y;
    
    piecePoint.x = self.gesturePieceOrigin.x + point.x;
    piecePoint.y = self.gesturePieceOrigin.y + point.y;
    pieceView.center = piecePoint;
    
    if (self.delegate)
        [self.delegate puzzleView:self pieceMoved:pieceView.tag toPoint:piecePoint];
}

//allowing interactions with puzzle pieces outside the bounds
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
        for (UIView *subview in self.subviews.reverseObjectEnumerator) {
            CGPoint subPoint = [subview convertPoint:point fromView:self];
            UIView *result = [subview hitTest:subPoint withEvent:event];
            if (result != nil) {
                return result;
            }
        }
    }
    
    return nil;
}

- (NSInteger)numberOfPieces
{
    return 20;
}

@end
