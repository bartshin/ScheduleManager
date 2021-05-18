//
//  WidgetHeader.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/17/21.
//

import SwiftUI
import WidgetKit

struct DateSquare: View {
    
    private let config: UserConfig
    /// Number of today schedules : ( Total, Completed )
    private let scheduleCount: Int
    private let date: Date
    private let holiday: DataGather.Holiday?
    
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
        ZStack {
            GeometryReader { geometryProxy in
                Image(uiImage: config.character.image)
                    .resizable()
                    .frame(width: 80,
                           height: 80)
                    .position(x: 10,
                              y: geometryProxy.size.height * -0.4)
                
                VStack {
                    Text(String(date.day))
                        .foregroundColor(dateFontColor)
                        .font(.largeTitle)
                    Text(date.monthDayTimeKoreanString)
                        .foregroundColor(dateFontColor)
                    if holiday != nil {
                        Text(holiday!.title)
                            .font(.caption)
                            .foregroundColor(Color(config.palette.secondary))
                    }
                }
                .position(x: geometryProxy.size.width * 0.5,
                          y: geometryProxy.size.height * 0.5)
            }
        }
    }
    
   
    init(date: Date, holiday: DataGather.Holiday?, config: UserConfig, scheduleCount: Int) {
        self.date = date
        self.holiday = holiday
        self.config = config
        self.scheduleCount = scheduleCount
    }
}

struct DateInformationView_Previews: PreviewProvider {
    static var previews: some View {
        DateSquare(date: Date(),
                     holiday: DataGather.Holiday(dateInt:  Date().toInt, title: "Childeren's day", description: "", type: .national),
            config: UserConfig(),
            scheduleCount: 3)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
