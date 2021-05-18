

import SwiftUI

struct CalendarCellView: View {
    var date: Date?
    var isToday: Bool {
        date!.isSameDay(with: Date())
    }
    var schedules = [Schedule]()
    var sticker: Sticker?
    var searchRequest: CalendarController.SearchRequest?
    var holiday: HolidayGather.Holiday?
    var colorPalette: SettingController.ColorPalette!
    private var filteredSchedules: Array<Schedule>.SubSequence {
        let filtered = schedules.filter() {
            if let search = searchRequest {
                if search.priority != nil, search.priority != $0.priority{
                    return false
                }
                if search.text != nil{
                    return $0.title.lowercased().contains(search.text!) || $0.description.lowercased().contains(search.text!)
                }else {
                    return true
                }
            }else {
                return true
            }
        }
    
        return filtered.sortedByPriority.prefix(3)
    }
    private var dateFontColor: Color {
        if holiday != nil {
            if date!.weekDay == 1 || holiday!.type == .national {
                return Color.red
            }else if date!.weekDay == 7 {
                return Color.blue
            }else {
                return Color(colorPalette.tertiary)
            }
        }else {
            if date!.weekDay == 1 {
                return Color.pink
            }else if date!.weekDay == 7 {
                return Color.blue
            }else {
                return Color(colorPalette.primary)
            }
            
        }
    }
    
    var body: some View {
        
        GeometryReader{ geometry in
            if date != nil {
                VStack{
                    Text(String(date!.day))
                        .font(.body)
                        .overlay(isToday ? RoundedRectangle(
                                    cornerRadius: 10)
                                    .stroke(Color.red.opacity(0.8),
                                            lineWidth: 2.5)
                                    : nil)
                    if holiday != nil{
                        Text(holiday!.title)
                            .font(holiday!.title.count > 10 ? .system(size: 7): .system(size: 10))
                            .lineLimit(1)
                    }
                }
                .foregroundColor(dateFontColor)
                .position(x: geometry.size.width / 2,
                          y: geometry.size.height * 0.15)
                .frame(maxHeight: geometry.size.height * 0.2)
                Rectangle()
                    .frame(width: geometry.size.width * 1.1,
                           height: 2)
                    .position(x: geometry.size.width / 2 ,
                              y: geometry.size.height * 0.3)
                    .foregroundColor(dateFontColor.opacity(0.5))
                ZStack {
                    if sticker != nil {
                        let size = min (geometry.size.width,  geometry.size.height)
                        Image(uiImage: sticker!.image)
                            .resizable()
                            .frame(width: size, height: size)
                            .opacity(schedules.count == 0 ? 1: 0.6)
                    }
                    VStack(alignment: .leading){
                        ForEach(filteredSchedules, id:\.id) { schedule in
                            HStack{
                                let scheduleColor = schedule.isDone(for: date!.toInt) ? Color(.lightGray): Color.byPriority(schedule.priority)
                                
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
                            .frame(width: geometry.size.width,
                                   height:
                                    (geometry.size.height * 0.7) / CGFloat(schedules.count + 1),
                                   alignment: .leading)
                        }
                    }
                    
                }
                .position(x: geometry.size.width * 0.5,
                          y: geometry.size.height * 0.65)
            }
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
            searchRequest: nil,
            holiday: nil, colorPalette: .pastel)
            .frame(
                width: 200,
                height: 300,
                alignment: .center)
            .border(Color.black)
    }
}

