//
//  RepositoryCell.swift
//  RealmExamples
//
//  Created by kishikawakatsumi on 11/20/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import UIKit

class RepositoryCell: UICollectionViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    override func prepareForReuse() {
        avatarImageView.image = nil
        titleLabel.text = nil
    }
}
