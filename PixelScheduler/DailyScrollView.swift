//
//  DailyScrollView.swift
//  PixelScheduler
//
//  Created by Shin on 2/26/21.
//

import SwiftUI

struct DailyScrollView: View, DailyScrollViewProtocol {
	
	// MARK: Data
	/// Date current presenting
	var date: Date?
	@ObservedObject var dataSource: DailyViewDataSource
	private var isToday: Bool
	var tapSchedule: ((Schedule) -> Void)
	var labelLanguage: SettingKey.DateLanguage
	
	// MARK: - View Properties
	
	var visualMode: SettingKey.VisualMode
	var colorPalette: SettingKey.ColorPalette
	private let lineHeight: CGFloat
	private var scrollViewHeight: CGFloat {
		lineHeight * 24
	}
	
	private let timeLineID = "currentTimeLine"
	private let alldayScheduleID = "alldaySchedules"
	
	var body: some View {
		ScrollViewReader { scrollViewProxy in
			GeometryReader { geometryProxy in
				ScrollView {
					ZStack (alignment: .topLeading){
						drawBaseLine(in: geometryProxy)
						Group {
							if date != nil {
								drawUniqueSchedules(in: geometryProxy)
								drawOverlappedSchedules(in: geometryProxy)
							}
						}
						if !dataSource.schedulesAllDay.isEmpty {
							drawAlldaySchedules(geometryProxy: geometryProxy, scrollViewProxy: scrollViewProxy)
						}
						if isToday {
							drawTodayLine(geometryProxy: geometryProxy, scrollViewProxy: scrollViewProxy)
						}
					}
				}
				.frame(maxHeight: .infinity)
				.background(backgroundGradient)
			}
		}
	}
	
	private func drawBaseLine(in geometryProxy: GeometryProxy) -> some View {
		DailyTableBaseLine(
			width: geometryProxy.size.width,
			lineHeight: lineHeight,
			color: Color(colorPalette.secondary).opacity(0.5),
			labelLanguage: labelLanguage
		)
		.ignoresSafeArea()
	}
	
	private func drawUniqueSchedules(in geometryProxy: GeometryProxy) -> some View {
		
		ForEach(
			Array(dataSource.schedulesUnique.enumerated()), id: \.element.id) { index, schedule in
			let backgroundHeight =  lineHeight * calcHeight(for: schedule.time)
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
			.onDrag{
				NSItemProvider(object: schedule.id.uuidString as NSString)
			}
		}
	}
	
	@ViewBuilder
	private func drawOverlappedSchedules(in geometryProxy: GeometryProxy) -> some View {
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
	
	@ViewBuilder
	private func drawAlldaySchedules(geometryProxy: GeometryProxy, scrollViewProxy: ScrollViewProxy) -> some View {
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
					scrollViewProxy.scrollTo(alldayScheduleID, anchor: .topTrailing)
				}
			}
	}
	@ViewBuilder
	private func drawTodayLine(geometryProxy: GeometryProxy, scrollViewProxy: ScrollViewProxy) -> some View {
		DailyTableCurrentTimeLine(width: geometryProxy.size.width)
			.id(timeLineID)
			.frame(width: geometryProxy.size.width,
						 height: 5)
			.alignmentGuide(.top) { context in
				-(CGFloat(Date().timeToDouble) * (lineHeight))
			}
			.onAppear{
				withAnimation {
					scrollViewProxy.scrollTo(timeLineID, anchor: .center)
				}
			}
	}
	
	private var backgroundGradient: LinearGradient {
		LinearGradient(gradient: Gradient(
										stops: [.init(color: Color(colorPalette.tertiary.withAlphaComponent(0)),
																	location: CGFloat(0)),
														.init(color: Color(colorPalette.tertiary.withAlphaComponent(0.1)),
																	location: CGFloat(0.8)),
														.init(color: Color(colorPalette.tertiary.withAlphaComponent(0.2)),
																	location: CGFloat(1))]),
									 startPoint: .top,
									 endPoint: .bottom)
	}
	
	init(data: DailyViewDataSource, date: Date?, colorPalette: SettingKey.ColorPalette, visualMode: SettingKey.VisualMode, language: SettingKey.DateLanguage) {
		self.date = date
		self.isToday = date != nil ? date!.isSameDay(with: Date()) : false
		self.dataSource = data
		self.lineHeight = 60
		self.tapSchedule = {_ in }
		self.colorPalette = colorPalette
		self.labelLanguage = language
		self.visualMode = visualMode
	}
	
	fileprivate init(with dummy: [Schedule]) {
		self.date = Date()
		let data = DailyViewDataSource()
		data.setNewSchedule(dummy, of: Date())
		self.dataSource = data
		self.lineHeight = 60
		self.tapSchedule = {_ in }
		self.isToday = false
		self.colorPalette = .basic
		self.labelLanguage = .korean
		self.visualMode = .system
	}
}

struct DailyScrollView_Previews: PreviewProvider {
	static var previews: some View {
		DailyScrollView(with: [])
	}
}
