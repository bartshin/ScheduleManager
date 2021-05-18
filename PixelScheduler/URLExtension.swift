//
//  Promise.swift
//  Schedule_B
//
//  Created by Shin on 2/20/21.
//

import Foundation
import UIKit

extension URLRequest {
    func sendWithPromise(_ givenPromise: Promise<Data>? = nil) -> Future<Data> {
        let promise = givenPromise == nil ? Promise<Data>(): givenPromise!
        
        let task = URLSession.shared.dataTask(with: self) {
            data, _, error in
            if let error = error {
                promise.reject(with: error)
            }else {
                promise.resolve(with: data ?? Data())
            }
        }
        task.resume()
        
        return promise
    }
}

extension URL {
    static func localURLForXCAsset(name: String) -> URL? {
        let fileManager = FileManager.default
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {return nil}
        let url = cacheDirectory.appendingPathComponent("\(name).png")
        let path = url.path
        if !fileManager.fileExists(atPath: path) {
            guard let image = UIImage(named: name), let data = image.pngData() else {return nil}
            fileManager.createFile(atPath: path, contents: data, attributes: nil)
        }
        return url
    }
}
