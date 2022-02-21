//
//  TaskCollection.swift
//  PixelScheduler
//
//  Created by Shin on 3/25/21.
//

import Foundation
import UIKit

struct TaskCollection: Hashable, Codable, Identifiable {
	
	var style: Style
	var title: String
	var puzzleConfig: PuzzleConfig?
	let id: UUID
	
	enum Style: String, Codable, Equatable {
		case puzzle
		case list
		
		var iconImageName: String {
			switch self {
			case .puzzle:
				return "puzzlepiece.extension"
			case .list:
				return "checklist"
			}
		}
	}
	
	init(style: Style, title: String) {
		self.style = style
		self.title = title
		self.id = UUID()
	}
	
	// Dummy data
	static let  listCollectionDummy = TaskCollection(style: .list, title: "쇼핑 리스트 (샘플)")
	static let puzzleCollectionDummy: TaskCollection = {
		var collection = TaskCollection(style: .puzzle, title: "보고 싶은 영화 (샘플)")
		collection.puzzleConfig = PuzzleConfig(
			backgroundImage: PuzzleBackground.allCases.filter({ $0.isFree
			}).randomElement()!,
			numRows: 3, numColumns: 3)
		return collection
	}()
}

// Puzzle config

extension TaskCollection {
	
	struct PuzzleConfig: Hashable, Codable {
		var backgroundImage: PuzzleBackground
		var numRows: Int
		var numColumns: Int
	}
	
	enum PuzzleBackground: String, CaseIterable, Codable {
		
		case backToSchool = "back_to_school"
		case champagne
		case castle
		case desert
		case city
		case rockDesert = "rock_desert"
		case cactusDesert = "cactus_desert"
		case bambooValley = "bamboo_valley"
		case mushrooms
		case forest
		case oldTown = "old_town"
		case village
		
		var image: UIImage {
			UIImage(named: self.rawValue)!
		}
		
		var isFree: Bool {
			switch self {
			case .backToSchool, .champagne, .castle, .desert:
				return true
			default:
				return false
			}
		}
		
		var pickerName: String {
			switch self {
			case .backToSchool:
				return "Back To School"
			case .castle:
				return "Castle"
			case .champagne:
				return "Champagne"
			case .oldTown:
				return "Old town"
			case .city:
				return "City"
			case .village:
				return "Village"
			case .desert:
				return "Desert"
			case .rockDesert:
				return "Desert - rock"
			case .cactusDesert:
				return "Desert - cactus"
			case .forest:
				return "Forest"
			case .mushrooms:
				return "Mushrooms"
			case .bambooValley:
				return "Velly - bamboo"
			}
		}
	}
}
