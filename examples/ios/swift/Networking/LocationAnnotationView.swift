//
//  LocationAnnotationView.swift
//  RealmExamples
//
//  Created by Samuel Giddins on 12/12/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import MapKit

class LocationAnnotationView: MKAnnotationView {
    var iconImage: UIImage? {
        didSet {
            iconImageView.image = iconImage
            if let image = iconImage {
                let adjustmentDivisor: CGFloat = 2.1
                let adjustedImageSize = CGSize(width: image.size.width / adjustmentDivisor, height: image.size.height / adjustmentDivisor)
                iconImageView.frame = CGRect(x: CGRectGetWidth(bounds) / 2.0 - adjustedImageSize.width / 2.0, y: CGRectGetWidth(bounds) / 2.0 - adjustedImageSize.height / 2.0, width: adjustedImageSize.width, height: adjustedImageSize.height)
            }
            setNeedsDisplay()
        }
    }

    var venueScore: Double = -1 {
        didSet {
            venueScoreView.venueScore = venueScore
            if venueScore >= 0 {
                leftCalloutAccessoryView = nil
            }
            else {
                leftCalloutAccessoryView = venueScoreView
            }
            setNeedsDisplay()
        }
    }

    let iconImageView = UIImageView()
    let shadowPathFillColor = UIColor(white: 0, alpha: 0.2)
    let foursquareBlueColor = UIColor(red: 28/255, green: 173/255, blue: 236/255, alpha: 1)
    let venueScoreView = VenueScoreView(frame: CGRectZero)

    override init!(annotation: MKAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clearColor()
        addSubview(iconImageView)
        venueScoreView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        venueScoreView.venueScore = venueScore
        rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as UIView
        frame = CGRect(origin: CGPointZero, size: CGSize(width: 38.5, height: 49.0))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        iconImage = nil
        venueScore = -1
    }

    override func drawRect(rect: CGRect) {
        let xCenter = rect.size.width / 2
        let shadowWidth  = rect.size.width  * 0.44
        let shadowHeight = rect.size.height * 0.08

        // Draw shadow
        let shadowPath = UIBezierPath(ovalInRect: CGRectMake(xCenter - shadowWidth / 2, rect.size.height - shadowHeight, shadowWidth, shadowHeight))
        shadowPathFillColor.setFill()
        shadowPath.fill()

        // Draw outer pin
        let strokeWidth = 9.0
        let halfStrokeWidth = strokeWidth / 2
        let referenceAngle = 145.0
        let radius = Double(xCenter)
        let referenceAngleRadians = referenceAngle / 180 * M_PI
        let xOffset = radius * cos(referenceAngleRadians)
        let yOffset = radius * sin(referenceAngleRadians)
        let circlePath = UIBezierPath()
        circlePath.moveToPoint(CGPoint(x: radius + xOffset, y: radius + yOffset))
        circlePath.addArcWithCenter(CGPoint(x: radius, y: radius), radius: CGFloat(radius), startAngle: CGFloat(referenceAngleRadians), endAngle: CGFloat(3 * M_PI) - CGFloat(referenceAngleRadians), clockwise: true)
        circlePath.addLineToPoint(CGPoint(x: CGFloat(radius), y: rect.size.height - shadowHeight / 2))
        circlePath.closePath()
        UIColor.whiteColor().setFill()
        circlePath.fill()
        UIColor.darkGrayColor().setStroke()
        circlePath.lineWidth = 0.1
        circlePath.stroke()

        // Draw circle
        let circleRadius = Double((rect.size.width - CGFloat(strokeWidth)) / 2)
        let circleXOffset = radius * cos(referenceAngleRadians)
        let circleYOffset = radius * sin(referenceAngleRadians)
        let innerCirclePath = UIBezierPath()
        let circleCenter = CGPoint(x: circleRadius + halfStrokeWidth, y: circleRadius + halfStrokeWidth)
        innerCirclePath.moveToPoint(CGPoint(x: halfStrokeWidth + circleRadius + circleXOffset, y: halfStrokeWidth + circleRadius + circleYOffset))
        innerCirclePath.addArcWithCenter(circleCenter, radius: CGFloat(circleRadius), startAngle: CGFloat(referenceAngleRadians), endAngle: CGFloat(referenceAngleRadians + 2 * M_PI), clockwise: true)
        innerCirclePath.closePath()
        foursquareBlueColor.setFill()
        innerCirclePath.fill()
    }
}
