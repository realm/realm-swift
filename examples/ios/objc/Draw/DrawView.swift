//
//  DrawView.swift
//  RealmExamples
//
//  Created by Adam Fish on 9/25/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit

class DrawView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var frame = self.swatchesView.frame
        frame.size.width = CGRectGetWidth(self.frame)
        frame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(frame)
        swatchesView.frame = frame
        
        swatchesView.setNeedsLayout()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) {
            return
        }
        
        // Create a draw point object
        let drawPoint = DrawPoint()
        drawPoint.x = point.x
        drawPoint.y = point.y
        
        let colorName = currentColor?.name ?? "Black"
        
        // Create a draw path object
        drawPath = DrawPath()
        drawPath.color = colorName
        
        // Add the draw point to the draw path
        drawPath.points.add(drawPoint)
        
        // Add the draw path to the Realm
        try! realm.write {
            realm.add(drawPath)
        }
    }
    
    func add(point: CGPoint) {
        let realm = try! Realm()
        try! realm.write {
            if drawPath.isInvalidated {
                drawPath = DrawPath()
                drawPath.color = currentColor?.name ?? "Black"
                realm.add(drawPath)
            }
            
            let newPoint = realm.create(DrawPoint.self, value: point)
            drawPath.points.add(newPoint)
        }
    }
}
