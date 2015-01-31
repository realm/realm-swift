//
//  VenueScoreView.swift
//  RealmExamples
//
//  Created by Samuel Giddins on 12/12/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import UIKit

class VenueScoreView: UIView {
    let venueScoreColorGreen = UIColor(red: 142/255, green: 212/255, blue: 0, alpha: 1)
    let venueScoreColorGray  = UIColor(red: 206/255, green: 203/255, blue: 198/255, alpha: 1)
    let venueScoreLabel = UILabel()
    var venueScore: Double {
        didSet {
            venueScoreLabel.text = NSString(format: "%0.01f", venueScore)
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        venueScore = 0
        super.init(frame: frame)
        venueScoreLabel.frame = bounds
        venueScoreLabel.textColor = UIColor.whiteColor()
        venueScoreLabel.textAlignment = .Center
        venueScoreLabel.font = UIFont.systemFontOfSize(14)
        addSubview(venueScoreLabel)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        if venueScore > 6 {
            venueScoreColorGreen.setFill()
        }
        else {
            venueScoreColorGray.setFill()
        }

        UIBezierPath(ovalInRect: rect).fill()
    }
}
