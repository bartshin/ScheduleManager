//
//  WidgetHeader.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/17/21.
//

import SwiftUI
import WidgetKit

struct DateInformationView: View {
    
    private let config: WidgetConfig
    /// Number of today schedules : ( Total, Completed )
    private let scheduleCount: Int
    private let label: String
    private let date: Date
    private let holiday: WidgetDataGather.Holiday?
    
    private var dateFontColor: Color {
        if holiday != nil {
            if date.weekDay == 1 || holiday!.type == .national {
                return Color.red
            }else if date.weekDay == 7 {
                return Color.blue
            }else {
                return Color(config.palette.tertiary)
            }
        }else {
            if date.weekDay == 1 {
                return Color.pink
            }else if date.weekDay == 7 {
                return Color.blue
            }else {
                return Color(config.palette.primary)
            }
            
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: nil) {
            Text(date.dayKoreanString)
                .foregroundColor(Color(config.palette.secondary))
            Text(label)
                .foregroundColor(Color(config.palette.primary))
            if scheduleCount > 0 {
            Text( "(\(scheduleCount))")
                .font(.body)
                .foregroundColor(Color(config.palette.primary))
            }
            Image(uiImage: config.character.image)
                .resizable()
                .rotation3DEffect(
                    .degrees(180),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
                .frame(width: 80,
                       height: 80)
        }
        .font(.custom("YANGJIN", size: 18))
    }
    
   
    init(date: Date, holiday: WidgetDataGather.Holiday?, label: String, config: WidgetConfig, scheduleCount: Int) {
        self.date = date
        self.holiday = holiday                      
        self.label = label
        self.config = config
        self.scheduleCount = scheduleCount
    }
}

struct WidgetHeader_Previews: PreviewProvider {
    static var previews: some View {
        DateInformationView(date: Date(),
                     holiday: WidgetDataGather.Holiday(dateInt: Date().toInt, title: "Childeren's day", description: "", type: .national),
            label: "일간 일정",
            config: WidgetConfig(),
            scheduleCount: 3)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
