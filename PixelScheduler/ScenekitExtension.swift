//
//  ScenekitExtension.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/14.
//

import SceneKit

extension SCNVector3 {
	static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3{
		SCNVector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
	}
	
	static func /<T>(lhs: SCNVector3, rhs: T) -> SCNVector3 where T: BinaryFloatingPoint {
		SCNVector3(x: lhs.x / Float(rhs), y: lhs.y / Float(rhs), z: lhs.z / Float(rhs))
	}
}

extension SCNNode {
	var size: SCNVector3 {
		SCNVector3(x: boundingBox.max.x - boundingBox.min.x,
							 y: boundingBox.max.y - boundingBox.min.y,
							 z: boundingBox.max.z - boundingBox.min.z)
	}
}

