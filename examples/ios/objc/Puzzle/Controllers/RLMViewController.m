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

#import "RLMViewController.h"
#import <Realm/Realm.h>
#import "RLMPuzzlePiece.h"
#import "RLMPuzzleView.h"
#import "RLMStartView.h"

static CGFloat kRLMPuzzleCanvasMaxSize = 735.0f;

@interface RLMViewController () <RLMPuzzleViewDelegate>

@property (nonatomic, strong) RLMStartView *startView;
@property (nonatomic, strong) RLMPuzzleView *puzzleView;
@property (nonatomic, strong) NSMutableArray *puzzlePieces;
@property (nonatomic, strong) RLMRealm *inMemoryRealm;

@end

@implementation RLMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.1f alpha:1.0f];
    
    //Scale the frame depending on screen size
    CGRect frame = CGRectZero;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        frame.size = (CGSize){kRLMPuzzleCanvasMaxSize, kRLMPuzzleCanvasMaxSize};
    }
    else {
        CGFloat width = MIN(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
        CGFloat canvasWidth = (768.0f / width) * kRLMPuzzleCanvasMaxSize;
        frame.size = (CGSize){canvasWidth,canvasWidth};
    }
    
    self.puzzleView = [[RLMPuzzleView alloc] initWithFrame:frame];
    self.puzzleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.puzzleView.frame = (CGRect){{floorf((CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.puzzleView.frame)) * 0.5f), floorf((CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.puzzleView.frame)) * 0.5f)}, self.puzzleView.frame.size};
    self.puzzleView.delegate = self;
    [self.view addSubview:self.puzzleView];

    self.startView = [[RLMStartView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.startView];
    
    __block typeof(self) blockSelf = self;
    self.startView.startButtonTapped = ^{
        [UIView animateWithDuration:0.8f animations:^{
            blockSelf.startView.alpha = 0.0f;
        } completion:^(BOOL complete) {
            [blockSelf.puzzleView scramblePiecesAnimated];
        }];
    };
    
    if (self.inMemoryRealm)
        return;
    
    self.puzzlePieces = [NSMutableArray array];

    self.inMemoryRealm = [RLMRealm inMemoryRealmWithIdentifier:@"io.realm.puzzle"];
    for (NSInteger i = 0; i < self.puzzleView.numberOfPieces; i++) {
        RLMPuzzlePiece *piece = [[RLMPuzzlePiece alloc] init];
        piece.pieceID = i;

        [self.inMemoryRealm transactionWithBlock:^{
            [self.inMemoryRealm addObject:piece];
        }];
        
        [self.puzzlePieces addObject:piece];
    }
}

- (void)puzzleView:(RLMPuzzleView *)puzzleView pieceMoved:(RLMPuzzlePieceName)pieceID toPoint:(CGPoint)point
{
    RLMPuzzlePiece *piece = self.puzzlePieces[pieceID];
    [self.inMemoryRealm transactionWithBlock:^{
        piece.x = point.x;
        piece.y = point.y;
    }];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
