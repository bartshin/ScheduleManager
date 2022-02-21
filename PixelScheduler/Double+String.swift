//
//  Double+String.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/20.
//

import Foundation

extension Double {
	var stringTrimedDecimalIfZero: String {
		let remainder = self.truncatingRemainder(dividingBy: 1)
		
		if remainder == 0 {
			return String(Int(self))
		}else {
			return String(format: "%.2f", self)
		}
	}
}
