//
//  File.swift
//  FancyScheduler
//
//  Created by Shin on 4/1/21.
//

import Foundation
import UIKit

enum GoogleGuide: String {
	case desktop
	case setting
	case share
	
	var title: String {
		switch self {
		case .desktop:
			return "구글 캘린더 사이트 접속"
		case .setting:
				return "원하는 캘린더의 설정화면 들어가기"
		case .share:
			return "액세스 권한 변경"
		}
	}
	
	var text: String {
		switch self {
		case .desktop:
			return "구글 캘린더 페이지를 열어주세요 (https://calendar.google.com/calendar)\n 모바일에서 접속한 경우 화면 하단의 데스크탑을 눌러주세요"
		case .setting:
			return "화면 좌측 하단의 내 캘린더를 또는 다른 캘린더 중 원하는 캘린더의 오른쪽 부분을 눌러 팝업창을 연 뒤 설정 및 공유를 눌러주세요"
		case .share:
			return "액세스 권한 설정 항목에서 공개 사용 설정을 활성화 해주세요"
		}
	}
	
	var image: UIImage {
		UIImage(named: "google_guide_\(self.rawValue)")!
	}
}

enum CharacterPresentingGuide {
    
    case firstOpen
    case monthlyCalendar
    case weeklyCalendar
    case scheduleDetail
    case editSchedule
    case todoList
    case todoPuzzle
    case editCollection
    
    var instructions: [(String, NSAttributedString)] {
        switch self {
        case .firstOpen:
            return  [
                ("환영합니다", NSAttributedString(string: "Pixel Scheduler를 사용해 주셔서 감사합니다! \n  도움말을 보려면 언제든지 화면내의 캐릭터를 클릭해 주세요", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])),
                ("캘린더", UIImage(systemName: "calendar")!.makeAttributedString(with: " 날짜 별로 일정을 관리할 수 있어요")),
                ("할 일", UIImage(systemName: "list.dash")!.makeAttributedString(with: " 목록을 만들거나 퍼즐을 만들어 관리할 수 있어요")),
                ("외부 캘린더 가져오기", UIImage(systemName: "gearshape.2")!.makeAttributedString(with: " 설정 탭에서 외부 캘린더에서 일정을 가져올 수 있어요")),
                ("맞춤 설정", UIImage(systemName: "gearshape.2")!.makeAttributedString(with: " 설정 탭에서 화면 설정, 테마 등을 변경하고 캐릭터를 고를 수 있어요"))
            ]
        case .monthlyCalendar:
            return [
                ("일별 일정 보기", UIImage(systemName: "hand.tap")!.makeAttributedString(with: " 원하는 날짜를 눌러 이동할 수 있어요")),
                ("새로운 일정 추가", UIImage(named: "add_schedule_orange")!.makeAttributedString(with: " 화면 하단  우측의 버튼을 눌러 주세요")),
                ("이전 달과 다음달 보기", UIImage(systemName: "arrow.up.and.down.and.arrow.left.and.right")!.makeAttributedString(with: " 달력으로 사용중일때는 상하로 스크롤으로 사용중일때는 좌우로 밀어 넘길 수 있어요 설정에서 변경 할 수 있어요")),
                ("년도와 월 찾기", UIImage(systemName: "calendar")!.makeAttributedString(with: " 버튼을 클릭하면 쉽게 찾을 수 있어요")),
                ("일정 필터링 및 검색", UIImage(systemName: "magnifyingglass")!.makeAttributedString(with: "버튼을 눌러 색상을 고르거나 텍스트를 입력해 실시간으로 필터링 할 수 있어요 검색 버튼을 누르면 검색창이 열려요"))
            ]
        case .weeklyCalendar:
            return [
                ("날짜 이동하기", UIImage(systemName: "arrow.left.and.right")!.makeAttributedString(with: " 화면 상단을 좌우로 넘긴뒤 원하는 날짜를 눌러서 이동할 수 있어요")),
                ("일간 일정보기", UIImage(systemName: "rectangle.arrowtriangle.2.outward")!.makeAttributedString(with: " 화면을 위 아래로 움직여 일정을 찾은 뒤 눌러서 세부 내용을 볼 수 있어요")),
                ("새로운 일정 추가", UIImage(named: "add_schedule_blue")!.makeAttributedString(with: " 화면 하단 우측 버튼을 눌러 주세요")),
                ("스티커 고르기", UIImage(named: "sticker_icon")!.makeAttributedString(with: " 화면 하단 좌측 버튼을 눌러 주세요"))
            ]
        case .scheduleDetail:
            return [
                ("완료 하기", UIImage(systemName: "checkmark.seal")!.makeAttributedString(with: " 화면 하단의 버튼을 눌러 완료와 미완료를 바꿀 수 있어요")),
                ("수정 하기", NSAttributedString(string: "화면 오른쪽 위의 버튼을 눌러 주세요 기간이 있는 일정이나 반복이 설정된 일정은 모두 변경되니 주의해 주세요", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])),
                ("알람 켜고 끄기", UIImage(systemName: "alarm")!.makeAttributedString(with: " 버튼을 눌러주세요 알람이 등록 되어 있다면 켜고 끌 수 있어요")),
                ("연락하기", UIImage(systemName: "phone")!.makeAttributedString(with: " 버튼을 눌러 주세요 아이폰의 연락처 앱으로 연결됩니다")),
                ("길 찾기", UIImage(named: "apple_maps_icon")!.makeAttributedString(with: " 버튼을 눌러 주세요 아이폰 기본 지도앱으로 연결됩니다")),
                ("삭제하기", UIImage(systemName: "trash")!.withTintColor(.red).makeAttributedString(with: " 화면 하단의 버튼을 눌러 삭제할 수 있어요 기간이 있는 일정이나 반복이 설정된 일정은 모두 지워지니 주의해 주세요"))
            ]
        case .editSchedule:
            return [
                ("스케쥴 기간", NSAttributedString(string: "원하는 날짜와 시간 / 시작과 끝이 있는 기간 / 매주 원하는 요일 반복 / 매달 원하는 날짜 반복 \n 각각 다른 종류의 기간을 정할 수 있어요", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)]
                )),
                ("반복", UIImage(systemName: "repeat.circle")!.makeAttributedString(with: " 날짜 선택에서 기준 날짜와 시간을 정해주세요 \n 그 뒤 원하는 요일이나 날짜를 선택하면 기준 날짜 이후에 한꺼번에 등록돼요")
                 ),
                ("알람 등록", NSAttributedString(string: " 알람을 허용해 주세요 설정에서 변경할 수 있어요. \n 반복되는 일정의 알람을 등록하면 여러 알람이 한번에 등록돼요", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])),
                ("연락처 등록", NSAttributedString(string: "스케줄에 관련된 연락처를 등록할 수 있습니다 ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])),
                ("위치 등록", NSAttributedString(string: "일정에 관련된 위치를 등록할 수 있어요 \n 위치 권한을 허용하면 현재 위치도 볼 수 있어요 \n 검색을 이용해 위치를 찾거나 지도를 꾹 눌러 직접 고를 수도 있어요", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)]))
            ]
        case .todoPuzzle:
            return [
                ("퍼즐 추가하기", UIImage(named: "puzzle")!.makeAttributedString(with: " 화면 하단 우측의 버튼을 눌르거나 퍼즐의 빈 곳을 눌러 새로운 퍼즐 조각을 추가할 수 있어요")),
                ("퍼즐 맞추기", UIImage(systemName: "puzzlepiece.fill")!.makeAttributedString(with: " 목표를 완료했다면 추가한 퍼즐을 눌러 완료 버튼을 눌러 주세요 \n 퍼즐이 너무 작을땐 퍼즐을 확대할 수 있어요")),
                ("퍼즐 바꾸기", UIImage(named: "puzzles")!.makeAttributedString(with: " 화면 좌측 하단의 버튼을 눌러 원하는 퍼즐 갯수와 퍼즐의 그림을 바꿀 수 있어요"))
            ]
        case .todoList:
            return [
                ("리스트 추가하기", UIImage(named: "pencil")!.makeAttributedString(with: " 화면 하단 우측의 버튼을 눌러 새로운 항목을 추가해주세요")),
                ("완료하기", UIImage(systemName: "arrow.right")!.makeAttributedString(with: " 리스트를 왼쪽에서 오른쪽으로 캐릭터가 나와서 항목을 완료할 거에요")),
                ("삭제하기", UIImage(systemName: "arrow.left")!.makeAttributedString(with: " 리스트를 오른쪽에서 왼쪽으로 밀어서 항목을 삭제할 수 있어요")),
                ("변경하기", UIImage(systemName: "hand.tap")!.makeAttributedString(with: "항목의 내용을 클릭하면 변경할 수 있어요"))
            ]
        case .editCollection:
            return [
                ("컬렉션 만들기", NSAttributedString(string: "원하는 목표나 작업들을 묶어 컬렉션으로 관리 할 수 있어요 \n 목록 마지막의 버튼을 눌러 주세요", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])),
                ("리스트 컬렉션", UIImage(systemName: "scroll")!.makeAttributedString(with: " 한눈에 쉽게 관리할 수 있는 목록이에요")),
                ("퍼즐 컬렉션", UIImage(systemName: "puzzlepiece")!.makeAttributedString(with: " 목표를 이뤄가며 퍼즐을 하나씩 맞출 수 있어요")),
                ("컬렉션 이름 변경", UIImage(systemName: "arrow.right")!.makeAttributedString(with: " 컬렉션을 왼쪽에서 오른쪽으로 밀어 이름을 바꿀 수 있어요")),
                ("컬렉션 삭제", UIImage(systemName: "arrow.left")!.makeAttributedString(with: " 컬렉션을 오른쪽에서 왼쪽으로 밀어 삭제할 수 있어요 \n 컬렉션과 함께 내용도 지워져요"))
            ]
        }
    }
}
