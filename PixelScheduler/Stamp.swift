//
//  Stamp.swift
//  PixelScheduler
//
//  Created by Shin on 4/22/21.
//

import Foundation

struct Sticker: Codable {
    
    var number: Int {
        get {
            return _number
        }
        set {
            if newValue > 0, newValue < 11 {
                _number = newValue
            }else {
                assertionFailure("Invaild number: \(newValue) for stamp \(self)")
            }
        }
    }
    var _number: Int
    var collection: Collection
    
    enum Collection: String, Codable, CaseIterable {
        case celebration
        case entertainment
        case family
        case gaming
        case hobby
        case holiday
        case nature
        case party
        case sports
        case summer
        case transport
        case weather
        case winter
        
        var koreanName: String {
            switch self {
            case .celebration:
                return "기념일"
            case .entertainment:
                return "엔터테인먼트"
            case .family:
                return "가족"
            case .gaming:
                return "게임"
            case .hobby:
                return "취미"
            case .nature:
                return "자연"
            case .party:
                return "파티"
            case .sports:
                return "스포츠"
            case .summer:
                return "여름"
            case .transport:
                return "교통"
            case .weather:
                return "날씨"
            case .winter:
                return "겨울"
            case .holiday:
                return "휴가"
            }
        }
    }
    
    init(collection: Collection, number: Int) {
        guard number > 0, number < 11 else {
            assertionFailure("Invaild number: \(number) for stamp \(collection)")
            self.collection = collection
            self._number = 1
            return
        }
        self.collection = collection
        self._number = number
    }
}
