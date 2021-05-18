
# 업데이트 계획

- 캘린더 화면 검색 시 결과창 제공
- 구글 캘린더 연결 가이드 화면 
- 휴일 텍스트 한국어 전환 기능
- 휴일 검색 기능
- 아이패드 지원


# 초기 개발 계획 

## UI

### Calendar View

앱 실행시 첫 화면

 **화면전환**

- Weekly 또는 Daily 화면
- 네비게이션 뷰를 사용한다면 루트 뷰에 해당

 **구현해야 할 기능**

- **스와이프로 표시되는 월을 전환하는 기능**

- 원하는 월을 직접 선택하는 기능
- 색상 또는 아이콘을 활용한 시인성
- 일정을 필터링
- 일정을 검색

### Daily View

각 날짜에 해당하는 일정을 보여주는 화면

 **화면전환**

- Monthly 화면
- 이웃한 날짜에 해당하는 Daily 화면
- 개별 일정에 대한 Event Detail 화면
- 새로운 일정을 추가하는 Edit 화면

 **구현해야 하는 기능**

- 일정을 완료로 전환
- 일정 삭제
- 일정을 필터링
- 일정을 검색

### Event detail view

하나의 일정을 보여주는 화면

 **화면전환**

- Weekly 또는 Monthly 화면
- 일정을 수정하는 Edit 화면
- 같은 날의 다른 일정을 보여주는 새로운 Event Detail 화면

**구현할 기능**

- 일정 수정
- 일정 삭제
- 일정을 완료로 전환
- 알림을 켜고 끄기
- 중요도 수정

### Edit view

**화면 전환**

- ( 취소 )  Daily 또는 Weekly 화면
- ( 완료 )  새로운 생성한 일정의 Event Detail 화면
- ( 수정 )  수정중이던 일정의 Event Detail 화면

 **구현 할 기능**

- 날짜와 시간 입력
- 제목, 상세 에 해당하는 텍스트 입력
- 사진 등록
- 알림 설정
- 중요도 설정

## Features

### CRUD

**제목과 세부 사항의 텍스트**

- 검색기능을 구현한다면 추가 구현 필요

 **시간과 날짜**

- 특정 시간 하나만 선택
- 시작과 종료의 기간 선택

 **알림 등록**

사진 등록 - 미구현

- UIImagePIcker, UIImagePickerDelegation

```swift
struct ImagePicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    let pickedImageHandler: (UIImage) -> ()

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {

    }
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // [Delegate] Navigation controller, UI Image picker controller

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.pickedImageHandler(image)
                withAnimation(.linear){
                    parent.isPresented = false
                }
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            withAnimation(.linear){
                parent.isPresented = false
            }
        }

    }
}
```

**위치 등록 **

- Mapkit

```swift
//Core location
import CoreLocation

class GetLocation: NSObject, CLLocationManagerDelegate {
    private var locationManager : CLLocationManager!
    private var isAvailableLocation = CLLocationManager.locationServicesEnabled()
    private(set) var latitude: Double?
    private(set) var logitude: Double?
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0] as CLLocation
        self.latitude = userLocation.coordinate.latitude
        self.logitude = userLocation.coordinate.longitude
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Fail to get location: \n \(error)")
    }
}

private var userLocation = GetLocation()
let coord = Coordinates(latitude: userLocation.latitude ?? defaultLatitude , 
longitude: userLocation.logitude ?? defaultLogitude)

//Map View

struct MapViewT: View {
    var coordinate: CLLocationCoordinate2D
    @State private var region = MKCoordinateRegion()

    var body: some View {
        Map(coordinateRegion: $region)
            .onAppear {
                setRegion(coordinate)
            }
    }

    private func setRegion(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
    }
}

//Pick Location
```
    
### SAVE, LOAD

**Save, Load 시점**

- 앱 로딩시 일정 로드
- 일정 변동 발생 시 자동 저장
- 앱 전환 또는 앱 종료 전 자동 저장

 Save, Load 위치

**JSON 파일로 기기 내부에 저장**

```swift
//SAVE
func saveUserFile() {
        if let fileURL = userFilePath {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.spots)
                try data.write(to: fileURL)
            }catch {
                fatalError("Couln't write json data:\n \(error)")
            }
        }else {
            fatalError("Couln't get file path for saving")
        }
    }

//LOAD
func loadFile(){
        let data: Data
        let fileURL: URL
        if boolUserFileExist {
            fileURL = userFilePath!
        }else {
            if let defaultURL = Bundle.main.url(forResource: dataFileName, withExtension: nil) {
                    fileURL = defaultURL
            }else {
                fatalError("Count't get default data file")
            }
        }
        do {
            data = try Data(contentsOf: fileURL)
        }catch {
            fatalError("Couln't load \(dataFileName) from main bundle: \n \(error)")
        }
        do {
            let decoder = JSONDecoder()
            self.spots = try decoder.decode([Spot].self, from: data)
        } catch {
            fatalError("Couln't parse \(dataFileName): \n\(error)")
        }
    }

//HELPER
private var userFilePath: URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            return nil
        }
        return documentURL.appendingPathComponent(dataFileName)
    }
private var boolUserFileExist: Bool {
        if let fileURL = userFilePath {
            do {
                return try fileURL.checkResourceIsReachable()
            }catch {
                return false
            }
        }else {
            return false
        }
    }
```

**Userdefault에 저장(테마, 설정 등) **

```swift
//SAVE
let defaultKey = "myDataFile" 
@Published private var document: MyDocumentType
private var autoSaveCancellable: AnyCancellable = $document.sink {
    UserDefaults.standard.setValue(JSONEncoder().encode($0), forKey: defaultsKey)
}

//LOAD
init?(json: Data?) {
    if json != nil, let document = try? JSONDecoder().decode(MyDocumentType, 
            from: json!) {
        self = document
    }else {
        return nil
    }
}
```
### Notification

 **특정 날짜,시간  반복 알림**

```swift
/* class UNCalendarNotificationTrigger : UNNotificationTrigger */

var date = DateComponents()
date.hour = 8
date.minute = 30 
let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
```

