//
//  RepositoryCell.h
//  RealmExamples
//
//  Created by Katsumi Kishikawa on 11/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RepositoryCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end
