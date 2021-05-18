//
//  CustomWidgetURL.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/18/21.
//

import Foundation

struct CustomWidgetURL{
    
    static let urlScheme = "pixelscheduler"
    static func create(for type: WidgetObject, at date: Date?, objectID: UUID?) -> URL {
        var components = URLComponents()
        components.scheme = urlScheme
        components.host = type.rawValue
        components.queryItems = []
        if date != nil {
            components.queryItems!.append(URLQueryItem(name: "dateInt", value: String(date!.toInt)))
        }
        if objectID != nil {
            components.queryItems?.append(URLQueryItem(name: "id", value: objectID!.uuidString))
        }
        
        return components.url!
    }
    
    enum WidgetObject: String {
        case schedule
        case date
        case taskCollection
    }
}
