//
//  MultiSegmentView.swift
//  Schedule_B
//
//  Created by Shin on 2/28/21.
//

import SwiftUI

struct MultiSegmentView: View {
    
    // Read from outside
    class Shared: ObservableObject {
       @Published var selectedIndices = Set<Int>()
    }

    // MARK: Data
    @ObservedObject var shared = Shared()
    @State private var dateToAdd: Int = 1
    private var weekdays = Calendar.koreanWeekDays
    
    // MARK:- View properties
    
    var currentSegmentType: segmentType = .weekly
    
    private let selectedColor = Color.blue
    private let unSelectedColor = Color(white: 0.95)
    private func colorOfDay(_ day: String) -> Color {
        switch day {
        case "일":
            return Color.pink
        case "토":
            return Color.blue
        default:
            return Color.black
        }
    }
    /// Index of  selected date type
    enum segmentType: Int {
        case weekly = 2
        case monthly = 3
    }
    
    var body: some View {
        GeometryReader{ geometry in
            Group {
                switch currentSegmentType {
                case .weekly:
                    HStack(spacing: 10) {
                        ForEach(Array(weekdays.enumerated()), id: \.element) { index, weekday in
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .foregroundColor(Color.black)
                                    .frame(width: 35,
                                           height: 35)
                                RoundedRectangle(cornerRadius: 15)
                                    .foregroundColor(shared.selectedIndices.contains(index) ? selectedColor : unSelectedColor)
                                    .frame(width: 33,
                                           height: 33)
                                Text(weekday)
                                    .foregroundColor(shared.selectedIndices.contains(index) ? .white : colorOfDay(weekday))
                                    .font(.title3)
                                    .bold()
                            }
                            .onTapGesture {
                                if shared.selectedIndices.contains(index) {
                                    shared.selectedIndices.remove(index)
                                }else {
                                    shared.selectedIndices.insert(index)
                                }
                            }
                        }
                    }
                    .onAppear {
                        shared.selectedIndices.removeAll()
                    }
                case .monthly:
                    
                    HStack{
                        VStack {
                            Text("매 월 ")
                            ForEach(shared.selectedIndices.sorted(by: <), id: \.self) {
                                Text("\($0) 일")
                            }
                        }
                        Picker(selection: $dateToAdd, label: Text("매달 ")) {
                            ForEach(1..<32){
                                Text("\($0) 일")
                            }
                        }
                        .frame(maxWidth: geometry.size.width * 0.2)
                        Button(action: {
                            shared.selectedIndices.insert(dateToAdd + 1)
                        }, label: {
                            HStack{
                                Image(systemName: "plus.circle")
                                Text("반복 추가")
                            }
                        })
                    }
                    .onAppear {
                        shared.selectedIndices.removeAll()
                    }
                    .offset(x: geometry.size.width * 0.05)
                }
            }
            .frame(width: geometry.size.width,
                   height: geometry.size.height, alignment: .center)
        }
    }
}

struct MultiSegmentView_Previews: PreviewProvider {
    static var previews: some View {
        MultiSegmentView()
            .frame(width: 350, height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}

