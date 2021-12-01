

import SwiftUI

struct CalendarCellView: View, HolidayColor {
	
	var date: Date
	var isToday: Bool {
		date.isSameDay(with: Date())
	}
	var schedules: [Schedule]
	var sticker: Sticker?
	@Binding var searchRequest: (text: String, priority: Int)
	var holiday: HolidayGather.Holiday?
	var colorPalette: SettingKey.ColorPalette
	var labelLanguage: SettingKey.Language = .korean
	var hapticMode: SettingKey.HapticMode = .off
	
	private var filteredSchedules: Array<Schedule>.SubSequence {
		let filtered = schedules.filter() {
			if !searchRequest.text.isEmpty || searchRequest.priority != 0  {
				if searchRequest.priority != 0, searchRequest.priority != $0.priority{
					return false
				}
				if !searchRequest.text.isEmpty{
					return $0.title.lowercased().contains(searchRequest.text) || $0.description.lowercased().contains(searchRequest.text)
				}else {
					return true
				}
			}else {
				return true
			}
		}
		
		return filtered.sortedByPriority.prefix(3)
	}
	
	private func isScheduleDraggable(_ schedule: Schedule) -> Bool {
		switch schedule.time{
		case .spot(_):
			return true
		case .period(let startDate, let endDate):
			return startDate.isSameDay(with: endDate)
		case .cycle(_, _, _):
			return false
		}
	}
	
	var body: some View {
		GeometryReader{ geometry in
			dateLabel
				.position(x: geometry.size.width / 2,
						  y: geometry.size.height * 0.1)
				.frame(maxHeight: geometry.size.height * 0.1)
				.zIndex(1)
			divider
				.frame(width: geometry.size.width * 1.1,
					   height: 2)
				.position(x: geometry.size.width / 2 ,
						  y: geometry.size.height * 0.2)
			ZStack {
				if sticker != nil {
					let size = min (geometry.size.width,  geometry.size.height)
					drawSticker(for: size)
				}
				VStack(alignment: .leading){
					ForEach(filteredSchedules, id:\.id) { schedule in
						Group {
							if isScheduleDraggable(schedule) {
								draggableScheduleRow(for: schedule)
							}else {
								drawScheduleRow(for: schedule)
							}
						}
						.frame(width: geometry.size.width,
							   height:
								(geometry.size.height * (holiday == nil ? 0.5: 0.4)) / CGFloat(max(schedules.count + 1, 2)),
							   alignment: .leading)
						.offset(y: (holiday == nil ? 0: geometry.size.height * 0.2))
					}
				}
			}
			.position(x: geometry.size.width * 0.5,
					  y: geometry.size.height * 0.5)
		}
	}
	
	private var dateLabel: some View {
		Text(String(date.day))
			.font(.body)
			.overlay(
				VStack {
					if isToday {
						RoundedRectangle(
							cornerRadius: 30)
							.stroke(Color.red.opacity(0.8),
									lineWidth: 3)
					}
					if holiday != nil{
						let title = holiday!.translateTitle(to: labelLanguage)
						Text(title)
							.font(title.count > 10 ? .system(size: 7): .system(size: 10))
							.lineLimit(1)
							.frame(height: 20)
							.offset(y: 20)
							.fixedSize()
					}
				}
			)
		.foregroundColor(getFontColor(for: date, with: holiday))
	}
	private var divider: some View {
		Rectangle()
			.foregroundColor(getFontColor(for: date, with: holiday).opacity(0.5))
	}
	
	private func drawSticker(for size: CGFloat) -> some View {
		Image(uiImage: sticker!.image)
			.resizable()
			.frame(width: size, height: size)
			.opacity(schedules.count == 0 ? 1: 0.6)
	}
	
	private func draggableScheduleRow(for schedule: Schedule) -> some View {
		drawScheduleRow(for: schedule)
			.onDrag {
				UIImpactFeedbackGenerator().generateFeedback(for: hapticMode)
				return NSItemProvider(object: schedule.id.uuidString as NSString)
			}
	}
	
	private func drawScheduleRow(for schedule: Schedule) -> some View {
		HStack{
			let scheduleColor = schedule.isDone(for: date.toInt) ? Color(.lightGray): Color.byPriority(schedule.priority)
			RoundedRectangle(cornerRadius: 10, style: .circular)
				.inset(by: CGFloat(4.5 - Double(schedules.count)))
				.fill(scheduleColor)
				.aspectRatio(0.3, contentMode: .fit)
			Text(schedule.title)
				.font(.system(size: 10))
				.lineLimit(1)
				.foregroundColor(scheduleColor)
				.padding(.leading, -5)
		}
	}
}



struct CalendarCell_Previews: PreviewProvider {
	static var previews: some View {
		CalendarCellView(
			date: Date(), schedules: [
				Schedule(title: "title",
								 description: "description",
								 priority: 1,
								 time: .period(start: Date().aMonthAgo,
															 end: Date().aMonthAfter),
								 alarm: .once(Date())),
				Schedule(title: "title",
								 description: "description",
								 priority: 2,
								 time: .spot(Date()),
								 alarm: .once(Date())),
				Schedule(title: "title",
								 description: "description",
								 priority: 3,
								 time: .spot(Date()),
								 alarm: .once(Date()))
			],
			sticker: Sticker(collection: .entertainment, number: 2),
			searchRequest: .constant(("", 0)),
			holiday: nil, colorPalette: .pastel)
			.previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/))
	}
}

