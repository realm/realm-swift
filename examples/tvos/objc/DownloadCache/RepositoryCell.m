//
//  RepositoryCell.m
//  RealmExamples
//
//  Created by Katsumi Kishikawa on 11/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

#import "RepositoryCell.h"

@implementation RepositoryCell

- (void)prepareForReuse {
    self.imageView.image = nil;
    self.titleLabel.text = nil;
}

@end
