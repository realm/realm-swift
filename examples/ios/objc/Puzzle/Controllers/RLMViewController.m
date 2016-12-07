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
#import <Realm/RLMRealmConfiguration+Sync.h>
#import <Realm/RLMSyncConfiguration.h>
#import "RLMPuzzle.h"
#import "RLMPuzzlePiece.h"
#import "RLMPuzzleView.h"
#import "RLMStartView.h"

static NSString *kRLMPuzzleUUID = @"7387fa06-dffa-4891-97e1-9e35c3898658";
static CGFloat kRLMPuzzleCanvasMaxSize = 768.0f;

@interface RLMViewController () <RLMPuzzleViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) RLMStartView *startView;
@property (nonatomic, strong) RLMPuzzleView *puzzleView;
@property (nonatomic, strong) NSMutableArray *puzzlePieces;

@property (nonatomic, strong) RLMNotificationToken *notificationToken;

@property (nonatomic, strong) RLMResults *puzzles;
@property (nonatomic, strong) NSString *currentPuzzleID;

@end

@implementation RLMViewController

#pragma mark - Controller Lifecycle -

- (void)dealloc
{
    [self removeNotifications];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
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
    self.startView.connectButtonTapped = ^{
        [weakSelf connectToServer];
    };
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetGestureRecognized:)];
    tapRecognizer.numberOfTouchesRequired = 3;
    tapRecognizer.numberOfTapsRequired = 3;
    [self.view addGestureRecognizer:tapRecognizer];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Puzzle State Management -
- (void)connectToServer
{
    self.startView.loading = YES;
    
    NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:9080", self.startView.hostName]];
    
    RLMSyncCredentials *credential = [RLMSyncCredentials credentialsWithUsername:self.startView.userName password:self.startView.password register:NO];
    [RLMSyncUser logInWithCredentials:credential authServerURL:authURL onCompletion:^(RLMSyncUser *user, NSError *error) {
        if (error) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"An Error Ocurred" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil]];
            self.startView.loading = NO;
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        
        NSURL *syncURL = [NSURL URLWithString:[NSString stringWithFormat:@"realm://%@:9080/~/Puzzle", self.startView.hostName]];
        
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        [configuration setSyncConfiguration:[[RLMSyncConfiguration alloc] initWithUser:user realmURL:syncURL]];
        [RLMRealmConfiguration setDefaultConfiguration:configuration];
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        RLMPuzzle *puzzle = [RLMPuzzle objectForPrimaryKey:kRLMPuzzleUUID];
        if (!puzzle) {
            RLMPuzzle *puzzle = [[RLMPuzzle alloc] init];
            puzzle.uuid = kRLMPuzzleUUID;
            [realm transactionWithBlock:^{
                [realm addObject:puzzle];
            }];
        }
        
        [self startPuzzle];
    }];
    
}

- (void)startPuzzle
{
    //Create the over-arching puzzle object
    RLMPuzzle *newPuzzle = [RLMPuzzle objectForPrimaryKey:kRLMPuzzleUUID];
    self.currentPuzzleID = newPuzzle.uuid;
    
    BOOL firstTime = NO;
    if (newPuzzle.pieces.count == 0) {
        RLMRealm *defaultRealm = [RLMRealm defaultRealm];
        [defaultRealm transactionWithBlock:^{
            //Create a data point for each puzzle piece
            for (NSInteger i = RLMPuzzlePieceIdentifierA1; i < RLMPuzzlePieceIdentifierNum; i++) {
                RLMPuzzlePiece *puzzlePiece = [[RLMPuzzlePiece alloc] init];
                puzzlePiece.identifier = i;
                [newPuzzle.pieces addObject:puzzlePiece];
            }
        }];
        
        firstTime = YES;
    }

    [UIView animateWithDuration:0.5f animations:^{
        self.startView.alpha = 0.0f;
    } completion:^(BOOL complete) {
        [self.startView removeFromSuperview];
        self.startView = nil;
        
        if (firstTime) {
            [self.puzzleView scramblePiecesAnimated];
        }
        else {
            [self updatePuzzleState];
        }
        
        [self setupNotifications];
    }];
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
- (void)resetGestureRecognized:(UITapGestureRecognizer *)gestureRecognizer
{
    if (self.startView) {
        return;
    }

    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Reset Puzzle" message:@"Do you want to re-shuffle the puzzle pieces?" preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.puzzleView scramblePiecesAnimated];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

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
}

@end
