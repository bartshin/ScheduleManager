//
//  CGPointDistance.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/01/31.
//

import CoreGraphics

extension CGPoint {
	func calcDistanceSquared(to point: CGPoint) -> CGFloat {
		return (self.x - point.x) * (self.x - point.x) + (self.y - point.y) * (self.y - point.y)
	}
}
