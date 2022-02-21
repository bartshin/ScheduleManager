//
//  DailyScrollView.swift
//  PixelScheduler
//
//  Created by Shin on 2/26/21.
//

import SwiftUI

struct DailyScrollView: View, DailyScrollViewProtocol {
	
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@Binding var alert: CharacterAlert<Text, Text>?
	
	/// Date current presenting
	var date: Date?
	@ObservedObject var dataSource: DailyViewDataSource
	private var isToday: Bool
	
	@Binding var presentingScheduleId: Schedule.ID?
	@Binding var floatingSchedule: WeeklyView.FloatingSchedule?
	
	private var schedulePresenting: Schedule? {
		guard let presentingScheduleId = presentingScheduleId else {
			return nil
		}
		return scheduleController.getSchedule(by: presentingScheduleId)
	}
	
	var labelLanguage: SettingKey.Language {
		settingController.language
	}
	
	var visualMode: SettingKey.VisualMode {
		settingController.visualMode
	}
	var colorPalette: SettingKey.ColorPalette {
		settingController.palette
	}
	private let hapticGenerator = UIImpactFeedbackGenerator()
	private let lineHeight: CGFloat = 60
	private var scrollViewHeight: CGFloat {
		lineHeight * 24
	}
	
	private let timeLineID = "currentTimeLine"
	
	init(data: DailyViewDataSource, date: Date?,
			 presentingScheduleId: Binding<Schedule.ID?>,
			 floatingSchedule: Binding<WeeklyView.FloatingSchedule?>,
			 alert: Binding<CharacterAlert<Text, Text>?>) {
		self.date = date
		self.isToday = date != nil ? date!.isSameDay(with: Date()) : false
		self.dataSource = data
		_presentingScheduleId = presentingScheduleId
		_floatingSchedule = floatingSchedule
		_alert = alert
	}
	
	var body: some View {
		GeometryReader { geometry in
			ScrollViewReader { scrollViewProxy in
				ScrollView {
					ZStack (alignment: .topLeading){
						drawBaseLine(in: geometry.size)
							.onTapGesture(perform: hidePresentingSchedule)
						if isToday, schedulePresenting != nil {
							drawTodayLine(in: geometry.size)
						}
						Group {
							if date != nil {
				 				drawUniqueSchedules(in: geometry.size)
								drawOverlappedSchedules(in: geometry.size)
							}
							if !dataSource.idsAllday.isEmpty {
								drawAlldaySchedules(in: geometry.size)
							}
						}
						if let floatingScheduleYPostion = floatingSchedule?.position?.y {
							GeometryReader { floatingLineGeometry in
								Rectangle()
									.fill(Color.yellow)
									.frame(width: geometry.size.width,
												 height: 3)
									.position(x: geometry.size.width/2,
														y: floatingScheduleYPostion - geometry.frame(in: .global).minY)
									.onAppear {
										print(floatingLineGeometry.frame(in: .named("dailyScrollView")))
									}
							}
						}
						if isToday, schedulePresenting == nil {
							drawTodayLine(in: geometry.size)
								.onAppear{
									withAnimation {
										scrollViewProxy.scrollTo(timeLineID, anchor: .center)
									}
								}
						}
					}
				}
				.coordinateSpace(name: "dailyScrollView")
				.frame(maxWidth: geometry.size.width, maxHeight: .infinity)
				.background(background)
				.onChange(of: dataSource.firstScheduleOfDay?.id) { newValue in
					scrollToFirstScheduleIfNeeded(in: scrollViewProxy)
				}
				
			}
		}
	}
	
	// MARK: - Gesture
	@State private var lastDragValue: DragGesture.Value?
	
	private func createDragGesture(for schedule: Schedule) -> some Gesture {
		DragGesture(minimumDistance: 0, coordinateSpace: .global)
			.onChanged { dragValue in
				guard let lastDragValue = lastDragValue else
				{
					if abs(dragValue.translation.height) < 20 {
						lastDragValue = dragValue
					}
					DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
						if let lastDragValue = lastDragValue,
							 floatingSchedule == nil{
							setFloatingSchedule(schedule, at: lastDragValue.location)
						}
					}
					return
				}
				guard dragValue.time.timeIntervalSince(lastDragValue.time) > 0.3 else {
					if abs(dragValue.translation.height) > 100 {
						self.lastDragValue = nil
						self.floatingSchedule = nil
					}
					return
				}
				if
					floatingSchedule?.id == schedule.id || (floatingSchedule != nil && abs(dragValue.translation.height) < 50)
						  {
					setFloatingSchedule(schedule, at: dragValue.location)
				}else {
					self.lastDragValue = nil
				}
			}
			.onEnded { dragValue in
				lastDragValue = nil
				floatingSchedule?.position = nil
			}
	}
	
	private func setFloatingSchedule(_ schedule: Schedule, at position: CGPoint) {
		if floatingSchedule == nil {
			SoundEffect.playSound(.pin)
			hapticGenerator.generateFeedback(for: settingController.hapticMode)
			withAnimation {
				floatingSchedule = .init(id: schedule.id, position: position)
			}
		}else {
			floatingSchedule = .init(id: schedule.id, position: position)
		}
	}
	
	private func tapSchedule(_ schedule: Schedule) {
		withAnimation {
			presentingScheduleId = schedule.id
		}
	}
	
	private func hidePresentingSchedule() {
		withAnimation {
			presentingScheduleId = nil
		}
	}
	
	private func drawBaseLine(in size: CGSize) -> some View {
		DailyTableBaseLine(
			width: size.width,
			lineHeight: lineHeight,
			color: Color(colorPalette.secondary).opacity(0.5),
			labelLanguage: labelLanguage
		)
			.contentShape(Rectangle())
			.ignoresSafeArea()
	}
	
	private func drawUniqueSchedules(in size: CGSize) -> some View {
		ForEach(
			Array(dataSource.idsUnique), id: \.self) {
				if let schedule = scheduleController.getSchedule(by: $0) {
					
					ZStack(alignment: .leading) {
						let scheduleHeight = lineHeight * calcHeight(for: schedule.time)
						if schedulePresenting != schedule {
							drawSqaureSchedule(
								schedule,
								in: CGSize(width: size.width * 0.7, height: scheduleHeight))
							if schedule.time.isMovable {
								drawPin(for: schedule)
									.offset(x: -20, y: scheduleHeight * -0.3)
							}
						}
						if date != nil,
							 schedule.id == presentingScheduleId{
							drawScheduleDetailView(in: size)
								.offset(x: size.width * -0.1)
						}
					}
					.alignmentGuide(.top) { context in
						-CGFloat(calcOriginY(for: schedule.time)) * lineHeight
					}
					.alignmentGuide(.leading) { context in
						-size.width * 0.25
					}
					.onTapGesture {
						tapSchedule(schedule)
					}
					.zIndex($0 == presentingScheduleId ? 1: 0)
				}
			}
	}
	
	private func drawPin(for schedule: Schedule) -> some View {
		let isSelected = floatingSchedule?.id == schedule.id
		return Image("pin_icon")
			.resizable()
			.frame(width: 30, height: 30)
			.shadow(color: isSelected ? Color(settingController.palette.tertiary): .gray, radius: 5, x: -5, y: 2)
			.offset(x: isSelected ? -20: 0, y: isSelected ? -10: 0)
			.rotation3DEffect(.degrees(isSelected ? -10: 30), axis: (x: 0, y: 1, z: 1), anchor: .bottom, anchorZ: 0, perspective: 1)
			.gesture(createDragGesture(for: schedule))
	}
	
	private func drawSqaureSchedule(_ schedule: Schedule, in size: CGSize) -> some View {
		 Group {
			 
			 DailyTableScheduleBackground(
				for: schedule,
					 width: size.width,
					 height: max(size.height, 80.0),
					 date: date!)
			 // MARK: Schedule Content
			 DailyScheduleContentsView(
				for: schedule,
					 with: colorPalette,
					 watch: dataSource)
				 .frame(width: size.width,
								height: max(size.height, 80.0))
		}
		 .opacity(floatingSchedule?.id == schedule.id ? 0.3: 1)
		.transition(.move(edge: .trailing).combined(with: .opacity))
	}
	
	@ViewBuilder
	private func drawOverlappedSchedules(in size: CGSize) -> some View {
		let sizeForSchedules = CGSize(width: size.width * 0.8, height: lineHeight * 24)
		ForEach(dataSource.idsOverlapped, id:  \.first!) {
			let scheduleGroup = $0.compactMap(scheduleController.getSchedule(by:))
				.sorted()
				if scheduleGroup.count < 3 {
					drawHalfSizeSchedules(scheduleGroup, in: sizeForSchedules)
				}else {
					drawOneThirdSizeSchedules(scheduleGroup, in: sizeForSchedules)
				}
		}
		.alignmentGuide(.leading) { context in
			-size.width * 0.2
		}
	}
	
	private func drawHalfSizeSchedules(_ schedules: [Schedule], in size: CGSize) -> some View {
		let isContainPresenting = schedulePresenting != nil && schedules.contains(schedulePresenting!)
		return HStack(alignment: .top ,spacing: 10) {
			ForEach(schedules) { schedule in
				let backgroundHeight =  lineHeight * calcHeight(for: schedule.time)
				ZStack (alignment: .center){
					if schedulePresenting == schedule {
						drawScheduleDetailView(in: size, fromLeft: schedule == schedules.first)
							.frame(width: size.width)
							.offset(x: schedule != schedules.first ? size.width * -0.1: 0)
					}else {
						let scheduleSize = CGSize(
							width: isContainPresenting ? 30: size.width * 0.5,
							height:  backgroundHeight > 150 ? 150 : backgroundHeight)
						drawSqaureSchedule(schedule, in: scheduleSize)
						.opacity(isContainPresenting ? 0.1: 1)
						.frame( width: scheduleSize.width, height: scheduleSize.height)
						if schedule.time.isMovable {
							drawPin(for: schedule)
								.offset(x: scheduleSize.width * -0.5,
												y: scheduleSize.height * -0.5)
						}
					}
				}
				.onTapGesture {
					tapSchedule(schedule)
				}
				.alignmentGuide(.top) { context in
					-CGFloat(calcOriginY(for: schedule.time)) * lineHeight
				}
			}
		}
	}
	
	private func drawOneThirdSizeSchedules(_ schedules: [Schedule], in size: CGSize) -> some View {
		
		let isContainPresenting = schedulePresenting != nil && schedules.contains(schedulePresenting!)
		return ZStack {
			HStack(alignment: .top) {
				ForEach(schedules) { schedule in
					ZStack {
						if !isContainPresenting {
							drawCapsule(for: schedule)
								.transition(.slide.combined(with: .opacity))
								.onTapGesture {
									tapSchedule(schedule)
								}
						}
						if schedule.id == presentingScheduleId,
							 let lastSchedule = schedules.last{
							drawScheduleDetailView(in: size, fromLeft: presentingScheduleId != lastSchedule.id)
								.offset(x: lastSchedule.id == presentingScheduleId ? size.width * -0.1: 0)
						}
					}
					.alignmentGuide(.top) { context in
						-CGFloat(calcOriginY(for: schedule.time)) * lineHeight
					}
				}
			}
			.frame(width: size.width)
		}
	}
	
	private func drawCapsule(for schedule: Schedule) -> some View {
		let titleColor = Color(colorPalette.primary)
		let descriptionColor = Color(colorPalette.secondary)
		let capsuleHeight =  lineHeight * calcHeight(for: schedule.time)
		return Group {
			Capsule(style: .circular)
				.foregroundColor(schedule.isDone(for: date!.toInt) ? .gray: Color.backgroundByPriority(schedule.priority))
			VStack {
				Text(schedule.title)
					.foregroundColor(titleColor)
					.withCustomFont(size: .title3, for: settingController.language)
				if capsuleHeight > 250 {
					Text(schedule.description)
						.foregroundColor(descriptionColor)
						.font(.subheadline)
				}
			}
			.id(schedule.id)
		}
		.padding(5)
		.frame(height: capsuleHeight)
	}
	
	@ViewBuilder
	private func drawAlldaySchedules(in size: CGSize) -> some View {
		let boxSize = CGSize(width: size.width * 0.7,
												 height: size.height * 0.2 * max(CGFloat(dataSource.idsAllday.count), 1.5))
		Group {
			if let presentingScheduleId = presentingScheduleId,
				 dataSource.idsAllday.contains(presentingScheduleId){
				drawScheduleDetailView(in: size)
			}else {
				DailyViewAlldaySchedule(
					scheduleIds: dataSource.idsAllday,
					with: colorPalette,
					in: boxSize,
					watch: dataSource,
					tapScheduleHandeler: tapSchedule)
					.frame(width: boxSize.width,
								 height: boxSize.height)
					.transition(.slide)
			}
		}
			.alignmentGuide(.leading) { _ in
				-boxSize.width * 0.25
			}
	}
	
	@ViewBuilder
	private func drawScheduleDetailView(in size: CGSize, fromLeft: Bool = true) -> some View {
		if let presentingScheduleId = presentingScheduleId,
			let schedule = scheduleController.getSchedule(by: presentingScheduleId){
			ScheduleDetailView(
				schedule: schedule,
				isPresenting: .init(get: {
					self.schedulePresenting != nil
				}, set: { presenting in
					if !presenting {
						self.presentingScheduleId = nil
					}
				}))
				.transition(.opacity.combined(with: .move(edge: fromLeft ? .leading: .trailing)))
				.frame(width: size.width * 0.8)
				.fixedSize(horizontal: false, vertical: true)
				.zIndex(2)
		}
	}
	
	@ViewBuilder
	private func drawTodayLine(in size: CGSize) -> some View {
		DailyViewTimeLine(width: size.width)
			.id(timeLineID)
			.frame(width: size.width,
						 height: 5)
			.alignmentGuide(.top) { context in
				-(CGFloat(Date().timeToDouble) * (lineHeight))
			}
	}
	
	private var background: some View {
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
	
	private func scrollToFirstScheduleIfNeeded(in scrollViewProxy: ScrollViewProxy) {
		guard !isToday,
					let firstScheduleID = dataSource.firstScheduleOfDay?.id,
					presentingScheduleId != firstScheduleID
		else {
						return
					}
		let isAlldaySchedule = dataSource.idsAllday.contains(firstScheduleID)
		DispatchQueue.main.async {
			withAnimation(.easeIn(duration: 0.5)) {
				scrollViewProxy.scrollTo(firstScheduleID, anchor: isAlldaySchedule ? .bottomTrailing: nil)
			}
		}
	}
}

#if DEBUG
struct DailyScrollView_Previews: PreviewProvider {
	@State static private var schedulePresenting: Schedule.ID? = nil
	@State static private var alert: CharacterAlert<Text, Text>? = nil
	@State static private var movingSchedule: WeeklyView.FloatingSchedule? = nil
	
	static var previews: some View {
		DailyScrollView(data: DailyViewDataSource(), date: Date(), presentingScheduleId: $schedulePresenting,
										floatingSchedule: $movingSchedule,
										alert: $alert)
			.environmentObject(ScheduleModelController.dummyController)
			.environmentObject(SettingController())
	}
}
#endif
