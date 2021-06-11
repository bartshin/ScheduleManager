//
//  UserDataContainer.swift
//  ScheduleManager
//
//  Created by Shin on 3/25/21.
//

import Foundation
import Combine

protocol UserDataContainer {
	
}

extension UserDataContainer {
	
	func store(data: Data, filename: String) throws {
		if let fileURL = getFilePath(for: filename, usingICloud: false) {
			do {
				try data.write(to: fileURL, options: .atomic)
			}catch {
				assertionFailure("Fail to store user data \(error.localizedDescription)")
				throw UserDataError.saveFail("데이터 저장에 실패했습니다")
			}
			
		}else {
			assertionFailure("Couln't get file path for saving: \(filename)")
			throw UserDataError.saveFail("데이터 저장에 실패했습니다")
		}
	}
	
	func backup(filename: String) throws {
		
		guard let fileURL = getFilePath(for: filename, usingICloud: false),
					let backupURL = getFilePath(for: filename + "_backup", usingICloud: false),
					let iCloudURL = getFilePath(for: filename + "_backup", usingICloud: true)
		else {
			throw UserDataError.iCloudError("아이클라우드를 이용할 수 없습니다")
		}
		do {
			if FileManager.default.fileExists(atPath: backupURL.path) {
				try FileManager.default.removeItem(at: backupURL)
			}
			if FileManager.default.fileExists(atPath: iCloudURL.path) {
				try FileManager.default.removeItem(at: iCloudURL)
			}
			try FileManager.default.copyItem(at: fileURL, to: backupURL)
			try FileManager.default.setUbiquitous(true, itemAt: backupURL, destinationURL: iCloudURL)
		}catch {
			print("fail to set backup \n \(error.localizedDescription)")
			throw UserDataError.iCloudError("아이클라우드를 이용할 수 없습니다")
		}
		
	}
	func startDownloadBackup(filename: String) {
		guard let iCloudURL = getFilePath(for: filename + "_backup", usingICloud: true) else  {
			return
		}
		do {
			try FileManager.default.startDownloadingUbiquitousItem(at: iCloudURL)
		}catch {
			print("fail to download backup \n \(error.localizedDescription)")
		}
	}
	func restoreBackup<T: Codable>(filename: String, as returnType: T.Type) throws -> T {
		guard let iCloudURL = getFilePath(for: filename + "_backup", usingICloud: true) else  {
			print("No icloud backup file for \(filename)")
			throw UserDataError.iCloudError("아이클라우드에서 데이터를 찾을 수 없습니다.")
		}
		do {
			let data = try Data(contentsOf: iCloudURL)
			return try JSONDecoder().decode(T.self, from: data)
		}catch {
			print("fail to read backup file :\(iCloudURL) \n \(error.localizedDescription)")
			throw UserDataError.iCloudError("아이클라우드에서 데이터를 복구 하는데 실패하였습니다.")
		}
	}
	func storeForWidget(data: Data, fileName: String) throws {
		guard let sharedURL = getSharedPath(for: fileName) else {
			assertionFailure("Fail to get shared path for \(fileName)")
			throw UserDataError.saveFail("위젯 데이터 저장에 실패했습니다")
		}
		do {
			try data.write(to: sharedURL)
		}catch {
			throw UserDataError.saveFail("위젯 데이터 저장에 실패했습니다")
		}
	}
	
	func restore<T: Codable>(filename: String, as returnType: T.Type) throws -> T {
		let data: Data
		
		guard let fileURL = getFilePath(for: filename, usingICloud: false) else {
			throw UserDataError.loadFail("데이터를 찾지 못했습니다")
		}
		do {
			data = try Data(contentsOf: fileURL)
		}catch {
			assertionFailure("Couln't load \(filename) from \(fileURL.path): \n \(error.localizedDescription)")
			throw UserDataError.loadFail("데이터를 불러오는데 실패했습니다")
		}
		do {
			return try JSONDecoder().decode(T.self, from: data)
		} catch {
			throw UserDataError.loadFail("데이터를 불러오는데 실패했습니다")
		}
	}
	
	
	
	func checkFileExist(for fileName: String, usingICloud: Bool) -> Bool {
		
		if usingICloud {
			if let fileURL = getFilePath(for: fileName + "_backup", usingICloud: true) {
				do {
					return try fileURL.checkResourceIsReachable()
				}catch {
					return false
				}
			}
		}else {
			if let fileURL = getFilePath(for: fileName, usingICloud: false) {
				do {
					return try fileURL.checkResourceIsReachable()
				}catch {
					return false
				}
			}
		}
		return false
	}
	
	private func getFilePath(for fileName: String, usingICloud: Bool) -> URL? {
		var documentURL: URL?
		if usingICloud {
			documentURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents", isDirectory: true)
		}else {
			documentURL = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
		}
		guard documentURL != nil else {
			return nil
		}
		return documentURL!.appendingPathComponent(fileName).appendingPathExtension("json")
	}
	private func getSharedPath(for fileName: String) -> URL? {
		guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bartshin.com.github.pxscheduler") else {
			return nil
		}
		return containerURL.appendingPathComponent(fileName).appendingPathExtension("json")
	}
}

fileprivate enum UserDataError: Error {
	case saveFail (String)
	case loadFail (String)
	case iCloudError (String)
}
