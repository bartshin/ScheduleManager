//
//  DailyOverlappedCell.swift
//  PixelScheduler
//
//  Created by Shin on 2/28/21.
//

import SwiftUI

struct DailyOverlappedCell: View, DailyScrollViewProtocol {
	
	// MARK: Data
	@ObservedObject var dataSource: DailyViewDataSource
	var date: Date?
	var schedules: [Schedule]
	private let tapSchedule: (Schedule) -> Void
	
	// MARK: View Properties
	private let colorPalette: SettingKey.ColorPalette
	private var titleColor: Color {
		Color(colorPalette.primary)
	}
	private var descriptionColor: Color {
		Color(colorPalette.secondary)
	}
	private let lineHeight: CGFloat
	private let size: CGSize
	
	var body: some View {
		Group{
			if schedules.count < 3 {
				HStack(alignment: .top ,spacing: 10) {
					ForEach(schedules) { schedule in
						let backgroundHeight =  lineHeight * calcHeight(for: schedule.time)
						ZStack (alignment: .center){
							DailyTableScheduleBackground(
								for: schedule,
									 width: size.width * 0.45,
									 height: backgroundHeight,
									 date: date!)
							DailyScheduleContentsView(for: schedule,
																					 with: colorPalette,
																					 watch: dataSource)
								.frame( width: size.width * 0.45,
												height: backgroundHeight > 150 ? 150 : backgroundHeight)
						}
						.onTapGesture {
							tapSchedule(schedule)
						}
						.alignmentGuide(.top) { context in
							-CGFloat(calcOriginY(for: schedule.time)) * lineHeight
						}
					}
					
				}
				.frame(width: size.width, height: size.height, alignment: .top)
			}else {
				HStack(alignment: .top) {
					ForEach(schedules) { schedule in
						let capsuleHeight =  lineHeight * calcHeight(for: schedule.time)
						Capsule(style: .circular)
							.foregroundColor(Color.backgroundByPriority(schedule.priority))
							.overlay(
								VStack {
									Text(schedule.title)
										.foregroundColor(titleColor)
										.font(.title2)
									if capsuleHeight > 250 {
										Text(schedule.description)
											.foregroundColor(descriptionColor)
											.font(.title3)
									}
								}
									.padding(5)
							)
							.onTapGesture {
								tapSchedule(schedule)
							}
							.frame(height: capsuleHeight)
							.alignmentGuide(.top) { context in
								-CGFloat(calcOriginY(for: schedule.time)) * lineHeight
							}
					}
				}
			}
		}
		.frame(width: size.width,
					 height: size.height, alignment: .top)
		
	}
	init(for schedules: [Schedule],
			 date: Date,
			 in size: CGSize,
			 lineHeight: CGFloat,
			 with palette: SettingKey.ColorPalette,
			 watch dataSource: DailyViewDataSource,
			 tapScheduleHandeler: @escaping (Schedule) -> Void) {
		self.schedules = schedules
		self.dataSource = dataSource
		self.date = date
		self.lineHeight = lineHeight
		self.size = size
		self.colorPalette = palette
		self.tapSchedule = tapScheduleHandeler
	}
}
