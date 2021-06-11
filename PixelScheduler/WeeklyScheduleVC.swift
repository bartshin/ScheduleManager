//
//  WeeklyScheduleVC.swift
//  Schedule_B
//
//  Created by Shin on 2/24/21.
//

import UIKit
import Combine

class WeeklyScheduleVC: UIViewController {
	
	//MARK: Controllers
	var settingController: SettingController!
	var modelController: ScheduleModelController! {
		didSet {
			observeScheduleCancellable = modelController.objectWillChange.sink {
				[self] _ in
				if dateIntChosen != nil {
					weeklyScheduleView.reloadData()
				}
			}
		}
	}
	
	//MARK:- Properties
	
	fileprivate let cellCountForPage = 7
	fileprivate let pageCount = 11
	fileprivate var centerIndex: Int {
		cellCountForPage*pageCount/2 + cellCountForPage/2
	}
	fileprivate var scrollByTap = false
	fileprivate var observeScheduleCancellable: AnyCancellable?
	@IBOutlet private weak var weeklyScheduleView: UICollectionView!
	
	@Published var dateIntChosen: Int! {
		didSet {
			leftMostCellDate = Calendar.current.date(byAdding: .day, value: -centerIndex, to: dateChosen)
		}
	}
	
	fileprivate var leftMostCellDate: Date!
	fileprivate var dateChosen: Date {
		dateIntChosen.toDate!
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		weeklyScheduleView.isPagingEnabled = true
		weeklyScheduleView.dataSource = self
		weeklyScheduleView.delegate = self
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		scrollToIndex(centerIndex, animated: false)
	}
	
	fileprivate func scrollToIndex(_ index: Int, animated: Bool) {
		let leftIndex = index - cellCountForPage/2
		let originX = WeeklyCell.size(in: weeklyScheduleView.bounds.size).width * CGFloat(leftIndex)
		weeklyScheduleView.setContentOffset(
			CGPoint(x: originX,
							y: weeklyScheduleView.bounds.origin.y), animated: animated)
	}
}

extension WeeklyScheduleVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return cellCountForPage*pageCount
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let weeklyCell = weeklyScheduleView.dequeueReusableCell(withReuseIdentifier: WeeklyCell.reuseID, for: indexPath) as? WeeklyCell else {
			return WeeklyCell()
		}
		weeklyCell.weeklyCellView.labelLanguage = settingController.dateLanguage
		return weeklyCell
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		guard let weeklyCell = cell as? WeeklyCell ,
					let date = Calendar.current.date(byAdding: .day, value: indexPath.row, to: leftMostCellDate) else {
			return
		}
		drawCell(weeklyCell, for: date.toInt, calendarView: weeklyScheduleView, with: settingController.palette)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return WeeklyCell.size(in: weeklyScheduleView.frame.size)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let selectedCell = collectionView.cellForItem(at: indexPath) as? WeeklyCell else {
			assertionFailure("Can't get date-int for selected cell")
			return
		}
		let dateInt = selectedCell.weeklyCellView.date.toInt
		dateIntChosen = dateInt
		selectedCell.weeklyCellView.isSelected = true
		scrollByTap = true
		scrollToIndex(indexPath.row, animated: true)
	}
	
	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		weeklyScheduleView.reloadData()
		scrollToIndex(centerIndex, animated: false)
		scrollByTap = false
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		guard !scrollByTap,
					let visibleLeftCell = weeklyScheduleView.subviews.first(where: {
						$0.frame.contains(weeklyScheduleView.contentOffset)
					}) as? WeeklyCell else {
			return
		}
		leftMostCellDate = Calendar.current.date(byAdding: .day, value: -cellCountForPage*pageCount/2, to: visibleLeftCell.weeklyCellView.date)
		weeklyScheduleView.reloadData()
		scrollToIndex(centerIndex, animated: false)
	}
	
	fileprivate func drawCell(_ cell: WeeklyCell, for dateInt: Int, calendarView: UICollectionView, with palette: SettingKey.ColorPalette)  {
		// toss date to cell
		cell.weeklyCellView.date = dateInt.toDate!
		cell.weeklyCellView.colorPalette = palette
		cell.weeklyCellView.schedules = modelController.getSchedules(for: dateInt)
		cell.weeklyCellView.holiday = modelController.holidayTable[dateInt]
		// adjust swift ui view
		cell.weeklyCellHC.view.translatesAutoresizingMaskIntoConstraints = false
		cell.weeklyCellHC.view.frame = cell.contentView.frame
		cell.contentView.addSubview(cell.weeklyCellHC.view)
		cell.layer.borderColor = .init(gray: 0.5, alpha: 0.5)
		cell.layer.borderWidth = 0.8
		cell.weeklyCellView.isSelected = dateInt == dateIntChosen
	}
}
