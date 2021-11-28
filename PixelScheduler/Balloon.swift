//
//  Balloon.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/26.
//

import SwiftUI

struct Balloon: Shape {
	func path(in rect: CGRect) -> Path {
		let horizontalRatio = rect.size.width / 150
		let verticalRatio = rect.size.height / 200
		var path = Path()
		path.move(to: CGPoint(x: 5.5 * horizontalRatio, y: 16.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 5.5 * horizontalRatio, y: 176.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 8.5 * horizontalRatio, y: 176.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 8.5 * horizontalRatio, y: 179.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 11.5 * horizontalRatio, y: 179.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 11.5 * horizontalRatio, y: 182.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 14.5 * horizontalRatio, y: 182.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 14.5 * horizontalRatio, y: 186.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 133.5 * horizontalRatio, y: 186.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 133.5 * horizontalRatio, y: 182.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 136.5 * horizontalRatio, y: 182.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 136.5 * horizontalRatio, y: 179.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 139.5 * horizontalRatio, y: 179.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 139.5 * horizontalRatio, y: 176.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 142.5 * horizontalRatio, y: 176.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 139.5 * horizontalRatio, y: 26.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 136.5 * horizontalRatio, y: 26.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 136.5 * horizontalRatio, y: 22.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 133.5 * horizontalRatio, y: 22.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 133.5 * horizontalRatio, y: 19.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 130.5 * horizontalRatio, y: 19.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 130.5 * horizontalRatio, y: 16.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 18.5 * horizontalRatio, y: 16.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 18.5 * horizontalRatio, y: 1.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 15.5 * horizontalRatio, y: 3.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 12.5 * horizontalRatio, y: 6.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 9.5 * horizontalRatio, y: 9.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 7.5 * horizontalRatio, y: 12.5 * verticalRatio))
		path.addLine(to: CGPoint(x: 5.5 * horizontalRatio, y: 16.5 * verticalRatio))
		return path
	}
	
}
