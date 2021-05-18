//
//  SpeechBalloon.swift
//  ScheduleManager
//
//  Created by Shin on 3/31/21.
//

import UIKit


class SpeechBalloon: UIView {
    
    var fillColor: UIColor!
    var width: CGFloat!
    var height: CGFloat!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        let balloonPath = createBallonPath(width: width, height: height)
        UIColor.black.setStroke()
        balloonPath.lineWidth = 4
        balloonPath.stroke()
        fillColor.setFill()
        balloonPath.fill()
    }
    
    private func createBallonPath(width: CGFloat = 150, height: CGFloat = 200) -> UIBezierPath {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        let horizontalRatio = width / 150
        let verticalRatio = height / 200
        //// Bezier Drawing
        context.saveGState()
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 5.5 * horizontalRatio, y: 16.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 5.5 * horizontalRatio, y: 176.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 8.5 * horizontalRatio, y: 176.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 8.5 * horizontalRatio, y: 179.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 11.5 * horizontalRatio, y: 179.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 11.5 * horizontalRatio, y: 182.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 14.5 * horizontalRatio, y: 182.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 14.5 * horizontalRatio, y: 186.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 133.5 * horizontalRatio, y: 186.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 133.5 * horizontalRatio, y: 182.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 136.5 * horizontalRatio, y: 182.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 136.5 * horizontalRatio, y: 179.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 139.5 * horizontalRatio, y: 179.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 139.5 * horizontalRatio, y: 176.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 142.5 * horizontalRatio, y: 176.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 139.5 * horizontalRatio, y: 26.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 136.5 * horizontalRatio, y: 26.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 136.5 * horizontalRatio, y: 22.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 133.5 * horizontalRatio, y: 22.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 133.5 * horizontalRatio, y: 19.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 130.5 * horizontalRatio, y: 19.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 130.5 * horizontalRatio, y: 16.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 18.5 * horizontalRatio, y: 16.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 18.5 * horizontalRatio, y: 1.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 15.5 * horizontalRatio, y: 3.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 12.5 * horizontalRatio, y: 6.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 9.5 * horizontalRatio, y: 9.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 7.5 * horizontalRatio, y: 12.5 * verticalRatio))
        bezierPath.addLine(to: CGPoint(x: 5.5 * horizontalRatio, y: 16.5 * verticalRatio))
        bezierPath.close()
        context.restoreGState()
        return bezierPath
    }

}
