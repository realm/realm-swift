//
//  RLMPuzzlePiece.h
//  Realm Puzzle
//
//  Created by Tim Oliver on 5/12/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@interface RLMPuzzlePiece : RLMObject

@property (nonatomic, assign) NSInteger pieceID;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;

@end
