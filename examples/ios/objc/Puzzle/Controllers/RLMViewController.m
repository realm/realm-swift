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
#import "RLMPuzzle.h"
#import "RLMPuzzlePiece.h"
#import "RLMPuzzleView.h"
#import "RLMStartView.h"
#import "RLMPuzzleListViewController.h"

static CGFloat kRLMPuzzleCanvasMaxSize = 768.0f;

@interface RLMViewController () <RLMPuzzleViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) RLMStartView *startView;
@property (nonatomic, strong) RLMPuzzleView *puzzleView;
@property (nonatomic, strong) NSMutableArray *puzzlePieces;

@property (nonatomic, strong) RLMNotificationToken *notificationToken;

@property (nonatomic, strong) RLMResults *puzzles;
@property (nonatomic, strong) NSString *currentPuzzleID;

- (void)setupNotifications;
- (void)removeNotifications;

- (void)startNewPuzzle;
- (void)startNewPuzzleWithName:(NSString *)name;
- (void)joinExistingPuzzle;

- (void)updatePuzzleState;

@end

@implementation RLMViewController

#pragma mark - Controller Lifecycle -
- (instancetype)init
{
    if (self = [super init]) {
       
    }
    
    return self;
}

- (void)dealloc
{
    [self removeNotifications];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
    
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
    
    __weak typeof(self) weakSelf = self;
    self.startView.startButtonTapped = ^{
        [weakSelf startNewPuzzle];
    };
    
    self.startView.joinButtonTapped = ^{
        [weakSelf joinExistingPuzzle];
    };
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Puzzle State Management -
- (void)startNewPuzzle
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Puzzle Name" message:@"Please enter a name for this new puzzle" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK",nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView textFieldAtIndex:0].text = @"My Puzzle";
    [alertView show];
}

- (void)alertView:(nonnull UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
        return;
    
    NSString *name = [alertView textFieldAtIndex:0].text;
    if (name.length == 0)
        name = @"My Puzzle";
    
    [self startNewPuzzleWithName:name];
}

- (void)startNewPuzzleWithName:(NSString *)name
{
    //Create the over-arching puzzle object
    RLMPuzzle *newPuzzle = [[RLMPuzzle alloc] init];
    newPuzzle.name = name;
    self.currentPuzzleID = newPuzzle.uuid;
    
    //Create a data point for each puzzle piece
    NSMutableArray *puzzlePieces = [NSMutableArray array];
    for (NSInteger i = RLMPuzzlePieceIdentifierA1; i < RLMPuzzlePieceIdentifierNum; i++) {
        RLMPuzzlePiece *puzzlePiece = [[RLMPuzzlePiece alloc] init];
        puzzlePiece.identifier = i;
        [puzzlePieces addObject:puzzlePiece];
    }
    
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    [defaultRealm transactionWithBlock:^{
        for (RLMPuzzlePiece *piece in puzzlePieces) {
            [newPuzzle.pieces addObject:piece];
        }
        
        [defaultRealm addObject:newPuzzle];
    }];

    [UIView animateWithDuration:0.5f animations:^{
        self.startView.alpha = 0.0f;
    } completion:^(BOOL complete) {
        [self.startView removeFromSuperview];
        
        [self.puzzleView scramblePiecesAnimated];
        [self setupNotifications];
    }];
}

- (void)joinExistingPuzzle
{
    RLMPuzzleListViewController *puzzleListController = [[RLMPuzzleListViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:puzzleListController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
    
    __weak typeof(self) weakSelf = self;
    puzzleListController.puzzleChosenHandler = ^(RLMPuzzle *puzzle) {
        weakSelf.currentPuzzleID = puzzle.uuid;
        [weakSelf updatePuzzleState];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [UIView animateWithDuration:0.5f animations:^{
            weakSelf.startView.alpha = 0.0f;
        } completion:^(BOOL complete) {
            [weakSelf.startView removeFromSuperview];
             [self setupNotifications];
        }];
    };
}

- (void)updatePuzzleState
{
    RLMPuzzle *puzzle = [RLMPuzzle objectForPrimaryKey:self.currentPuzzleID];
    if (puzzle == nil)
        return;
    
    for (RLMPuzzlePiece *piece in puzzle.pieces) {
        [self.puzzleView movePiece:piece.identifier toPoint:(CGPoint){piece.x, piece.y} animated:YES];
    }
}

#pragma mark - Puzzle View Delegate -
- (void)puzzleView:(RLMPuzzleView *)puzzleView pieceMoved:(RLMPuzzlePieceIdentifier)pieceIdentifier toPoint:(CGPoint)point
{
    RLMPuzzle *puzzle = [RLMPuzzle objectForPrimaryKey:self.currentPuzzleID];
    if (puzzle == nil || pieceIdentifier >= puzzle.pieces.count)
        return;
    
    RLMPuzzlePiece *piece = puzzle.pieces[pieceIdentifier];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        piece.x = point.x;
        piece.y = point.y;
    }];
}

#pragma mark - Notifications -
- (void)setupNotifications
{
    __weak typeof(self) weakSelf = self;
    RLMNotificationBlock block = ^(NSString *notification, RLMRealm *realm) {
        weakSelf.puzzles = [RLMPuzzle allObjects];
        [weakSelf updatePuzzleState];
    };
    
    _notificationToken = [[RLMRealm defaultRealm] addNotificationBlock:block];
}

- (void)removeNotifications
{
    [self.notificationToken stop];
    self.notificationToken = nil;
}

@end
