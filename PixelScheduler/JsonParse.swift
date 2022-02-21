//
//  JsonParse.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/01/28.
//

import Foundation

extension Data {
	func toJsonDictionary() -> [String:AnyObject]? {
		if let json = try? JSONSerialization.jsonObject(with: self, options: .mutableContainers) as? [String:AnyObject] {
			return json
		}else {
			return nil
		}
	}
}


