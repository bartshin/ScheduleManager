//
//  DailyScrollView.swift
//  Schedule_B
//
//  Created by Shin on 2/26/21.
//

import SwiftUI

struct DailyScrollView: View, DailyScrollViewProtocol {

    // MARK: Data
    /// Date current presenting
     var date: Date? {
        didSet {
            isToday = date!.isSameDay(with: Date())
        }
    }
    @ObservedObject var dataSource: ScrollviewDataSource
    private var isToday: Bool
    var tapSchedule: ((Schedule) -> Void)
    var labelLanguage: SettingController.DateLanguage = .korean
    
    // MARK:- View Properties
    
    var visualMode: SettingController.VisualMode!
    var colorPalette: SettingController.ColorPalette!
    private let lineHeight: CGFloat
    private var scrollViewHeight: CGFloat {
        lineHeight * 24
    }
    
    private let timeLineID: String
    private let alldayScheduleID: String
    
    init() {
        self.date = nil
        self.dataSource = ScrollviewDataSource()
        self.lineHeight = 60
        self.tapSchedule = {_ in }
        self.isToday = false
        self.timeLineID =  "currentTimeLine"
        self.alldayScheduleID =  "alldaySchedules"
    }
    
    fileprivate init(with dummy: [Schedule]) {
        self.date = Date()
        let data = ScrollviewDataSource()
        data.setNewSchedule(dummy, of: Date())
        self.dataSource = data
        self.lineHeight = 60
        self.tapSchedule = {_ in }
        self.isToday = false
        self.timeLineID =  "currentTimeLine"
        self.alldayScheduleID =  "alldaySchedules"
    }
    
    var body: some View {
        ScrollViewReader { scrollviewProxy in
            GeometryReader { geometryProxy in
                ScrollView {
                    ZStack (alignment: .topLeading){
                        // MARK:- Base lines
                        DailyTableBaseLine(
                            width: geometryProxy.size.width,
                            lineHeight: lineHeight,
                            color: Color(colorPalette.secondary).opacity(0.5),
                            labelLanguage: labelLanguage
                        )
                            .ignoresSafeArea()
                        Group {
                            ForEach(Array(dataSource.schedulesUnique.enumerated()), id: \.element.id) { index, schedule in
                                let backgroundHeight =  lineHeight * calcHeight(for: schedule.time)
                               
                                // Find y position of schedule
                                ZStack(alignment: .leading) {
                                    // MARK:- Background
                                    DailyTableScheduleBackground(
                                        for: schedule,
                                        width: geometryProxy.size.width * 0.8,
                                        height: backgroundHeight,
                                        date: date!,
                                        watch: dataSource)
                                    // MARK: - Schedule Content
                                    DailyScheduleContentsView(
                                        for: schedule,
                                        with: colorPalette,
                                        watch: dataSource)
                                        .frame(width: geometryProxy.size.width * 0.7,
                                               height: backgroundHeight > 150 ? 150 : backgroundHeight)
                                }
                                .alignmentGuide(.top) { context in
                                   -CGFloat(calcOriginY(for: schedule.time)) * lineHeight
                                }
                                .alignmentGuide(.leading) { context in
                                    -geometryProxy.size.width * 0.25
                                }
                                .onTapGesture {
                                    tapSchedule(schedule)
                                }
                            }
                            
                            // Draw group of schedule overlapped for each
                            let sizeForSchedules = CGSize(width: geometryProxy.size.width * 0.8, height: lineHeight * 24)
                            ForEach(dataSource.schedulesOverlapped, id:  \.first!.id) { scheduleGroup in
                                DailyOverlappedCell(for: scheduleGroup,
                                                    date: date!,
                                                    in: sizeForSchedules,
                                                    lineHeight: lineHeight,
                                                    with: colorPalette,
                                                    watch: dataSource,
                                                    tapScheduleHandeler: tapSchedule)
                                    .frame(width: sizeForSchedules.width,
                                           height: sizeForSchedules.height)
                            }
                            .alignmentGuide(.leading) { context in
                                -geometryProxy.size.width * 0.2
                            }
                        }
                        if !dataSource.schedulesAllDay.isEmpty {
                            let size = CGSize(width: geometryProxy.size.width * 0.7,
                                              height: geometryProxy.size.height * 0.2 * CGFloat(dataSource.schedulesAllDay.count))
                            DailyTableAlldaySchedule(
                                schedules: dataSource.schedulesAllDay,
                                with: colorPalette,
                                in: size,
                                watch: dataSource,
                                tapScheduleHandeler: tapSchedule)
                                .id(alldayScheduleID)
                                .frame(width: size.width,
                                       height: size.height)
                                .alignmentGuide(.top) { _ in
                                   -100
                                }
                                .alignmentGuide(.leading) { _ in
                                    -geometryProxy.size.width * 0.25
                                }
                                .onAppear{
                                    withAnimation {
                                        scrollviewProxy.scrollTo(alldayScheduleID, anchor: .topTrailing)
                                    }
                                }
                        }
                        if isToday {
                            DailyTableCurrentTimeLine(width: geometryProxy.size.width)
                                .id(timeLineID)
                                .frame(width: geometryProxy.size.width,
                                       height: 5)
                                .alignmentGuide(.top) { context in
                                    -(CGFloat(Date().timeToDouble) * (lineHeight))
                                }
                                .onAppear{
                                    withAnimation {
                                        scrollviewProxy.scrollTo(timeLineID, anchor: .center)
                                    }
                                }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .background(LinearGradient(
                                gradient: Gradient(
                                    stops: [
                                        .init(
                                            color: Color(colorPalette.tertiary.withAlphaComponent(0)),
                                            location: CGFloat(0)),
                                        .init(
                                            color: Color(colorPalette.tertiary.withAlphaComponent(0.1)),
                                            location: CGFloat(0.8)),
                                        .init(
                                            color: Color(colorPalette.tertiary.withAlphaComponent(0.2)),
                                            location: CGFloat(1)),
                                            
                                    ]),
                                startPoint: .top,
                                endPoint: .bottom))
                .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

struct DailyScrollView_Previews: PreviewProvider {
    static var previews: some View {
        DailyScrollView()
    }
}
