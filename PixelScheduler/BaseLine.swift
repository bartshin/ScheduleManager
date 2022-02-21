//
//  DailyTableBaseLine.swift
//  PixelScheduler
//
//  Created by Shin on 2/27/21.
//

import SwiftUI

struct DailyTableBaseLine: View {
    
    // MARK: View properties
    private let lineWidth: CGFloat
    private let lineHeight: CGFloat
    private let lineRange = Range(1...24)
    private let lineColor: Color
    private let labelLanguage: SettingKey.Language
    
    private func getTimeLabel(of ordinalNumber: Int) -> String{
        var hour: String
        if  ordinalNumber % 12 == 0 {
            hour = "12"
        }else if ordinalNumber % 12 < 10 {
            hour = "  \(ordinalNumber % 12)"
        }else {
            hour = "\(ordinalNumber % 12)"
        }
        
        switch labelLanguage {
        case .english:
            let label = ordinalNumber < 12 ? "  AM" : "  PM"
            return hour + label
        case .korean:
            let label =  ordinalNumber < 12 ? "오전 " : "오후 "
            return label + hour + "시"
        }
        
    }
    var body: some View {
        VStack(spacing: 0){
            ForEach(lineRange) { ordinalNumber in
                HStack {
                    Text(getTimeLabel(of: ordinalNumber))
                        .foregroundColor(lineColor)
                        .offset(x: 15, y: 30)
                    Path{ path in
                        path.move(to: CGPoint(x: 30, y: lineHeight))
                        path.addLine(to: CGPoint(x: lineWidth,
                                                 y: lineHeight))
                    }
                    .stroke(lineColor, lineWidth: 2)
                }
                .frame(width: lineWidth, height: lineHeight)
            }
            Spacer(minLength: 60)
        }
    }
    init(width: CGFloat, lineHeight: CGFloat, color: Color, labelLanguage: SettingKey.Language) {
        lineWidth = width
        self.lineHeight = lineHeight
        lineColor = color
        self.labelLanguage = labelLanguage
    }
}
