//
//  StringError.swift
//  FancyScheduler
//
//  Created by Shin on 4/8/21.
//

import Foundation

extension String: Error {}


extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
