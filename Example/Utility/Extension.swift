//
//  Extension.swift
//  Example
//
//  Created by William.Weng on 2024/8/8.
//

import UIKit
import AVFoundation
import AVKit
import Photos
import MediaPlayer
import WWPrint
import WWCompositionalLayout

// MARK: - 擴充用
extension Int: Subtractable {}
extension Double: Subtractable {}

// MARK: - Int (function)
extension Int {
    
    /// 單位轉換 (4567 => 4,687 bytes)
    /// - Parameter units: ByteCountFormatter.Units
    /// - Returns: String
    func _bytes(units: ByteCountFormatter.Units = [.useBytes]) -> String { return Int64(self)._bytes(units: units) }
}

// MARK: - Int64 (function)
extension Int64 {
    
    /// [單位轉換 (3188 => 3,188 bytes)](https://stackoverflow.com/questions/28268145/get-file-size-in-swift)
    /// - Parameter units: ByteCountFormatter.Units
    /// - Returns: String
    func _bytes(units: ByteCountFormatter.Units = [.useBytes]) -> String {
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = units
        formatter.countStyle = .file
        
        return formatter.string(fromByteCount: self)
    }
}

// MARK: - Set (function)
extension Set where Self.Element: Hashable {
    
    /// 切換Set (On <-> Off)
    /// - Parameter member: Self.Element
    mutating func _toggle(_ member: Self.Element) {
        if !contains(member) { self.insert(member); return }
        self.remove(member)
    }
}

// MARK: - TimeInterval (function)
extension TimeInterval {
    
    /// [秒 => 時間 (210.2799sec => 3 minutes, 30 seconds)](https://stackoverflow.com/questions/26794703/swift-integer-conversion-to-hours-minutes-seconds)
    /// - Parameters:
    ///   - calendar: 日曆
    ///   - unitsStyle: 輸出的方式
    ///   - allowedUnits: 想要看的單位
    ///   - zeroFormattingBehavior: 填充方式
    /// - Returns: String?
    func _time(calendar: Calendar, unitsStyle: DateComponentsFormatter.UnitsStyle, allowedUnits: NSCalendar.Unit, zeroFormattingBehavior: DateComponentsFormatter.ZeroFormattingBehavior) -> String? {
        
        let formatter = DateComponentsFormatter()
        
        formatter.calendar = calendar
        formatter.allowedUnits = allowedUnits
        formatter.unitsStyle = unitsStyle
        formatter.zeroFormattingBehavior = zeroFormattingBehavior
        
        return formatter.string(from: self)
    }
    
    /// [秒 => 時間 (210.2799sec => 00:03:30)](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/將秒數變成時分秒的-datecomponentsformatter-4c872a2f27e4)
    /// - Parameter allowedUnits: [NSCalendar.Unit](https://medium.com/@vitoo/hello-425fdc395af7)
    /// - Returns: String?
    func _time(allowedUnits: NSCalendar.Unit = [.hour, .minute, .second]) -> String? {
        return self._time(calendar: .current, unitsStyle: .positional, allowedUnits: allowedUnits, zeroFormattingBehavior: .pad)
    }
}

// MARK: - NSNumber (static function)
extension NSNumber {
    
    /// 轉換小數點有效位數 (四捨五入)
    /// - 123.456789._decimalPoint(2) => 123.46
    /// - Parameter decimal: 要轉換的小數位數
    /// - Returns: NSString
    func _decimalPoint(_ decimal: UInt) -> NSString {
        
        let format = "%.\(decimal)f"
        let string = String(format: format, doubleValue)
        
        return (string as NSString)
    }
    
    /// 顯示手機在顯示倍率的文字 - 0.5, 1.0, 2.0 => .5, 1, 2
    /// - Returns: String?
    func _zoomFormat() -> String? {
        let formatter = NumberFormatter()._minimumInteger(0)._minimumFraction(0)._maximumFraction(1)
        return formatter.string(from: self)
    }
}

// MARK: - NumberFormatter (function)
extension NumberFormatter {
    
    /// 設置整數部分最少需要的位數
    /// - Parameter digits: Int
    /// - Returns: Self
    func _minimumInteger(_ digits: Int) -> Self {
        self.minimumIntegerDigits = digits
        return self
    }
    
    /// 設置整數部分最多需要的位數
    /// - Parameter digits: Int
    /// - Returns: Self
    func _maximumInteger(_ digits: Int) -> Self {
        self.maximumIntegerDigits = digits
        return self
    }
    
    /// 設置小數部分最少需要的位數
    /// - Parameter digits: Int
    /// - Returns: Self
    func _minimumFraction(_ digits: Int) -> Self {
        self.minimumFractionDigits = digits
        return self
    }

    /// 設置小數部分最多需要的位數
    /// - Parameter digits: Int
    /// - Returns: Self
    func _maximumFraction(_ digits: Int) -> Self {
        self.maximumFractionDigits = digits
        return self
    }
}

// MARK: - ClosedRange (function)
extension ClosedRange where Self.Bound: Subtractable {
    
    /// 區間的間隔寬度 => upperBound - lowerBound
    /// - Returns: Self.Bound
    func _gap() -> Self.Bound { return upperBound - lowerBound }
}

// MARK: - Collection (override class function)
extension Collection {

    /// [為Array加上安全取值特性 => nil](https://stackoverflow.com/questions/25329186/safe-bounds-checked-array-lookup-in-swift-through-optional-bindings)
    subscript(safe index: Index) -> Element? { return indices.contains(index) ? self[index] : nil }
}

// MARK: - Collection (function)
extension Collection where Self.Element: CALayer {
    
    /// 將所有CALayer移除
    func _removeFromSuperlayer() {
        self.forEach { $0.removeFromSuperlayer() }
    }
}

// MARK: - CGSize (Operator Overloading)
extension CGSize {
    
    /// CGSize的加法
    /// - Parameters:
    ///   - lhs: CGSize
    ///   - rhs: CGSize
    /// - Returns: CGSize
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    /// CGSize的減法
    /// - Parameters:
    ///   - lhs: CGSize
    ///   - rhs: CGSize
    /// - Returns: CGSize
    static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    /// CGSize的乘法
    /// - Parameters:
    ///   - size: CGSize
    ///   - scalar: CGFloat
    /// - Returns: CGSize
    static func *(size: CGSize, scalar: CGFloat) -> CGSize {
        return CGSize(width: size.width * scalar, height: size.height * scalar)
    }
    
    /// CGSize的乘法
    /// - Parameters:
    ///   - scalar: CGFloat
    ///   - size: CGSize
    /// - Returns: CGSize
    static func *(scalar: CGFloat, size: CGSize) -> CGSize {
        return size * scalar
    }
    
    /// CGSize的除法
    /// - Parameters:
    ///   - size: CGSize
    ///   - scalar: CGFloat
    /// - Returns: CGSize
    static func /(size: CGSize, scalar: CGFloat) -> CGSize {
        return CGSize(width: size.width / scalar, height: size.height / scalar)
    }
    
    /// CGSize的除法
    /// - Parameters:
    ///   - scalar: CGFloat
    ///   - size: CGSize
    /// - Returns: CGSize
    static func /(scalar: CGFloat, size: CGSize) -> CGSize {
        return size / scalar
    }
}

// MARK: - CGSize (function)
extension CGSize {
    
    /// 取得長邊
    /// - Returns: CGFloat
    func _longerSide() -> CGFloat { return max(width, height) }
    
    /// 取得短邊
    /// - Returns: CGFloat
    func _shorterSide() -> CGFloat { return min(width, height) }
}

// MARK: - CGPoint (Operator Overloading)
extension CGPoint {
    
    /// CGPoint的加法
    /// - Parameters:
    ///   - lhs: CGPoint
    ///   - rhs: CGPoint
    /// - Returns: CGPoint
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    /// CGPoint的減法
    /// - Parameters:
    ///   - lhs: CGPoint
    ///   - rhs: CGPoint
    /// - Returns: CGPoint
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    /// CGPoint的乘法
    /// - Parameters:
    ///   - point: CGPoint
    ///   - scalar: CGFloat
    /// - Returns: CGPoint
    static func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    /// CGPoint的乘法
    /// - Parameters:
    ///   - scalar: CGFloat
    ///   - point: CGPoint
    /// - Returns: CGPoint
    static func *(scalar: CGFloat, point: CGPoint) -> CGPoint {
        return point * scalar
    }
    
    /// CGPoint的除法
    /// - Parameters:
    ///   - point: CGPoint
    ///   - scalar: CGFloat
    /// - Returns: CGPoint
    static func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x / scalar, y: point.y / scalar)
    }

    /// CGPoint的除法
    /// - Parameters:
    ///   - scalar: CGFloat
    ///   - point: CGPoint
    /// - Returns: CGPoint
    static func /(scalar: CGFloat, point: CGPoint) -> CGPoint {
        return point / scalar
    }
}

// MARK: - Date (function)
extension Date {
    
    /// 將UTC時間 => 該時區的時間
    /// - 2020-07-07 16:08:50 +0800
    /// - Parameters:
    ///   - dateFormat: 時間格式
    ///   - timeZone: 時區
    /// - Returns: String?
    func _localTime(with dateFormat: Constant.DateFormat = .full, timeZone: TimeZone) -> String? {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "\(dateFormat)"
        dateFormatter.timeZone = timeZone
        
        switch dateFormat {
        case .meridiem(formatLocale: let locale): dateFormatter.locale = locale
        default: break
        }
        
        return dateFormatter.string(from: self)
    }
}

// MARK: - Selector (function)
extension Selector {
    
    /// [延遲執行函數 => 取消 -> 執行 / @objc function](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-debounce-優化-search-時發送的-request-783dc4261f27)
    /// - Parameters:
    ///   - target: [AnyObject](https://www.jianshu.com/p/346e3ba4970d)
    ///   - delayTime: TimeInterval
    func _debounce(target: AnyObject, delayTime: TimeInterval = 0.3) {
        _cancelPreviousPerformRequests(with: target)
        target.perform(self, with: nil, afterDelay: delayTime)
    }
    
    /// [取消之前未執行的Selector](https://feijunjie.github.io/2019/07/05/20190705-iOS中取消延迟执行函数/)
    /// - Parameter target: AnyObject
    func _cancelPreviousPerformRequests(with target: AnyObject) {
        NSObject.cancelPreviousPerformRequests(withTarget: target, selector: self, object: nil)
    }
}

// MARK: - UIFont (static function)
extension UIFont {
    
    /// [產生系統等寬字型](https://medium.com/彼得潘的-swift-ios-app-開發教室/設定等寬字體-monospace-font-in-ios-bc359202bf9b)
    /// - Parameters:
    ///   - pointSize: CGFloat
    ///   - weight: UIFont.Weight
    /// - Returns: UIFont
    static func _monoSystemFont(ofSize pointSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        return monospacedDigitSystemFont(ofSize: pointSize, weight: weight)
    }
}

// MARK: - URL (function)
extension URL {
    
    /// 取得該資料夾的相關訊息
    /// - Parameter keys: Set<URLResourceKey>
    /// - Returns: Result<URLResourceValues, Error>
    func _directoryResourceValues(forKeys keys: Set<URLResourceKey>) -> Result<URLResourceValues, Error> {
        
        let info = FileManager.default._fileExists(with: self)
        
        if (!info.isDirectory) { return .failure(Constant.MyError.isNotDirectory) }
        if (!info.isExist) { return .failure(Constant.MyError.isNotExist) }
        
        do {
            let values = try resourceValues(forKeys: keys)
            return .success(values)
        } catch {
            return .failure(error)
        }
    }
    
    /// 取得該資料夾可用存儲空間
    /// - Returns: Result<Int64, Error>
    func _availableCapacity() -> Result<Int64, Error> {
        
        let result = _directoryResourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let values):
            if let capacity = values.volumeAvailableCapacityForImportantUsage { return .success(capacity) }
            return .failure(Constant.MyError.isNull)
        }
    }
    
    /// 測試該檔案的樣式 (UTType => MIME / .mov => com.apple.quicktime-movie => video/quicktime)
    /// - Parameter checkTypes: 是否包含在這些類型裡面
    /// - Returns: Result<UTType, Error>
    func _checkType(conforms types: [UTType]) -> Result<UTType, Error> {
        
        do {
            
            guard let fileType = try resourceValues(forKeys: [.contentTypeKey]).contentType else { return .failure(Constant.MyError.isEmpty) }
            
            var checkType: UTType?
            
            for type in types { if (fileType.conforms(to: type)) { checkType = type; break }}
            if let checkType = checkType { return .success(checkType) }
            
            return .failure(Constant.MyError.isEmpty)
            
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - FileManager (function)
extension FileManager {
    
    /// User的「暫存」資料夾
    /// - => ~/tmp/
    /// - Returns: URL
    func _temporaryDirectory() -> URL { return self.temporaryDirectory }
    
    /// [取得User的資料夾](https://cdfq152313.github.io/post/2016-10-11/)
    /// - UIFileSharingEnabled = YES => iOS設置iTunes文件共享
    /// - Parameter directory: User的資料夾名稱
    /// - Returns: [URL]
    func _userDirectory(for directory: FileManager.SearchPathDirectory) -> [URL] { return Self.default.urls(for: directory, in: .userDomainMask) }
    
    /// User的「文件」資料夾URL
    /// - => ~/Documents/ (UIFileSharingEnabled)
    /// - Returns: URL?
    func _documentDirectory() -> URL? { return self._userDirectory(for: .documentDirectory).first }
    
    /// 產生檔案相關資料夾的URL
    /// - Parameter type: Constant.FileManagerDirectoryType
    /// - Returns: URL?
    func _directoryURL(for type: Constant.FileManagerDirectoryType) -> URL? { return type.url() }
    
    /// 測試該檔案是否存在 / 是否為資料夾
    /// - Parameter url: 檔案的URL路徑
    /// - Returns: Constant.FileInformation
    func _fileExists(with url: URL?) -> Constant.FileInformation {

        guard let url = url else { return (false, false) }
        
        var isDirectory: ObjCBool = false
        let isExist = fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        return (isExist, isDirectory.boolValue)
    }
    
    /// [讀取資料夾 / 檔案名稱的列表 => ["1.png", "Demo"]](https://blog.csdn.net/pk_20140716/article/details/54925418)
    /// - Parameter url: [要讀取的資料夾路徑](https://blog.csdn.net/u011146511/article/details/79362028)
    /// - Returns: [String]?
    func _fileList(with url: URL?) -> Result<[String]?, Error> {
        
        guard let path = url?.path else { return .success(nil) }
        
        do {
            let fileList = try contentsOfDirectory(atPath: path)
            return .success(fileList)
        } catch {
            return .failure(error)
        }
    }
    
    /// 移除檔案
    /// - Parameter url: URL
    /// - Returns: Result<Bool, Error>
    func _removeFile(at url: URL?) -> Result<Bool, Error> {
        
        guard let url = url,
              _fileExists(with: url).isExist
        else {
            return .failure(Constant.MyError.isNotExist)
        }
        
        do {
            try removeItem(at: url)
            return .success(true)
        } catch  {
            return .failure(error)
        }
    }
    
    /// 清除資料夾內容
    /// - Parameter url: URL?
    /// - Returns: Result<[Bool], Error>
    func _cleanFolder(at url: URL?) -> Result<[Bool], Error> {
        
        guard let url = url,
              let pathList = try? _fileList(with: url).get()
        else {
            return .failure(Constant.MyError.isNotExist)
        }
        
        var isSussesArray: [Bool] = []
                
        pathList.forEach { path in
            
            guard let fileUrl = Optional.some(url.appendingPathComponent(path)),
                  let isSusses = try? _removeFile(at: fileUrl).get()
            else {
                return
            }
            
            isSussesArray.append(isSusses)
        }
        
        return .success(isSussesArray)
    }
    
    /// 寫入Data - 二進制資料
    /// - Parameters:
    ///   - url: 寫入Data的文件URL
    ///   - data: 要寫入的資料
    /// - Returns: Result<Bool, Error>
    func _writeData(_ data: Data?, to url: URL?) -> Result<Bool, Error> {
        
        guard let url = url,
              let data = data
        else {
            return .failure(Constant.MyError.isNotExist)
        }
        
        do {
            try data.write(to: url)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// 取得該資料夾可用存儲空間
    /// - Returns: Result<Int64, Error>
    func _availableCapacity(type: Constant.FileManagerDirectoryType) -> Result<Int64, Error> {
        
        guard let url = _directoryURL(for: type) else { return .failure(Constant.MyError.isNotExist) }
        return url._availableCapacity()
    }
}

// MARK: - CIImage (static function)
extension CIImage {
    
    /// 建立一個有圓角的矩形
    /// - Parameters:
    ///   - inputRadius: 圓角
    ///   - inputExtent: 尺寸 / 位置
    /// - Returns: CIImage?
    static func _roundedRectangle(radius: CGFloat, extent: CGRect) -> CIImage? {
        
        let roundedRectangleParameters: [String: Any] = [
            "inputRadius": radius,
            "inputExtent": CIVector(cgRect: extent)
        ]
        
        guard let filter = CIFilter._build(with: .roundedRectangleGenerator, parameters: roundedRectangleParameters),
              let outputImage = filter.outputImage
        else {
            return nil
        }
        
        return outputImage
    }
}

// MARK: - CIImage (function)
extension CIImage {
    
    /// CIImage => UIImage
    /// - Parameters:
    ///   - scale: CGFloat
    ///   - orientation: UIImage.Orientation
    /// - Returns: UIImage
    func _image(scale: CGFloat, orientation: UIImage.Orientation) -> UIImage {
        return UIImage(ciImage: self, scale: scale, orientation: orientation)
    }
    
    /// 加上遮罩圖形
    /// - Parameter maskImage: CIImage?
    /// - Returns: CIImage?
    func _maskImage(with maskImage: CIImage?) -> CIImage? {
        
        guard let maskImage = maskImage,
              let filter = CIFilter._build(with: .sourceInCompositing, parameters: [kCIInputImageKey: self, kCIInputBackgroundImageKey: maskImage]),
              let outputImage = filter.outputImage
        else {
            return nil
        }
        
        return outputImage
    }
    
    /// 產生有圓角遮罩的圖形
    /// - Parameter radius: CGFloat
    /// - Returns: CIImage?
    func _roundedCorners(radius: CGFloat) -> CIImage? {
        
        guard let cornerMaskImage = Self._roundedRectangle(radius: radius, extent: extent),
              let outputImage = self._maskImage(with: cornerMaskImage)
        else {
            return nil
        }
        
        return outputImage
    }
}

// MARK: - UIApplication (function)
extension UIApplication {
    
    /// [不再自動進入鎖定畫面](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/設定-isidletimerdisabled-讓-iphone-不再自動進入鎖定畫面-89e23f61333b)
    /// - Parameter isAwake: Bool
    func _awake(_ isAwake: Bool) {
        isIdleTimerDisabled = isAwake
    }
}

// MARK: - CGImage (function)
extension CGImage {
    
    /// CGImage => CIImage
    /// - Parameter options: [CIImageOption : Any]?
    /// - Returns: CIImage
    func _ciImage(options: [CIImageOption : Any]? = nil) -> CIImage {
        
        let ciImage = CIImage(cgImage: self, options: options)
        return ciImage
    }
}

// MARK: - UIImage (function)
extension UIImage {
    
    /// [建立縮圖](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/縮小圖片的-preparingthumbnail-94fdd6ff9c7e)
    /// - Parameter size: [尺寸大小](https://developer.apple.com/documentation/uikit/uiimage/3750835-preparingthumbnail)
    /// - Returns: UIImage?
    func _thumbnail(of size: CGSize) -> UIImage? { return preparingThumbnail(of: size) }
    
    /// 圖片翻動 => 鏡射 + 旋轉
    /// - Parameter orientation: 翻動的方向
    /// - Returns: UIImage?
    func _flip(with orientation: UIImage.Orientation = .upMirrored) -> UIImage? {
        
        guard let cgImage = cgImage else { return nil }
        
        let flipImage = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        return flipImage
    }
    
    /// 兩張圖片結合 => PIP模式
    /// - Parameters:
    ///   - pipImage: UIImage
    ///   - pipRect: CGRect
    /// - Returns: UIImage
    func _combinePipImage(_ pipImage: UIImage, pipRect: CGRect) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let combinedImage = renderer.image { _ in
            
            draw(in: CGRect(origin: .zero, size: size))
            pipImage.draw(in: pipRect)
        }
        
        return combinedImage
    }
    
    /// 切圓角
    /// - Parameter radius: 半徑
    /// - Returns: UIImage
    func _roundedCorners(radius: CGFloat? = nil) -> UIImage? {
        
        let maxRadius = min(size.width, size.height) * 0.5
        let cornerRadius: CGFloat
        
        if let radius = radius, (radius > 0) && (radius <= maxRadius) {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        let rect = CGRect(origin: .zero, size: size)
        
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    /// 置中的正方形遮罩
    /// - Parameter cornerRadius: 圓角半徑
    /// - Returns: UIImage
    func squareMasked(cornerRadius: CGFloat) -> UIImage {
        
        let shorterSide = min(size.width, size.height)
        let size = CGSize(width: size.width, height: size.height)
        let squareMaskPostion = CGPoint(x: (size.width - shorterSide) * 0.5, y: (size.height - shorterSide) * 0.5)
        let squareMaskSize = CGSize(width: shorterSide, height: shorterSide)
        
        let rect = CGRect(origin: squareMaskPostion, size: squareMaskSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            
            let path = UIBezierPath(rect: CGRect(origin: .zero, size: size))
            let cornerPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            
            draw(in: CGRect(origin: .zero, size: size))
            path.append(cornerPath.reversing())
            
            context.cgContext.addPath(path.cgPath)
            context.cgContext.clip()
            context.cgContext.clear(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - UIToolbar (function)
extension UIToolbar {
    
    /// 透明背景
    func _transparent() {
        setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        setShadowImage(UIImage(), forToolbarPosition: .any)
    }
}

// MARK: - UIView (static function)
extension UIView {
    
    /// 動畫關閉 / 啟動
    /// - Parameters:
    ///   - isEnabled: Bool
    ///   - action: () -> Void
    static func _animations(isEnabled: Bool, action: () -> Void) {
        
        CATransaction.begin()
        UIView.setAnimationsEnabled(isEnabled)
        CATransaction.setDisableActions(!isEnabled)
        
        action()
        
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
    }
}

// MARK: - UIView (function)
extension UIView {
        
    /// [座標轉換 - 中點](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用轉換座標的-convert-function-判斷點選的-cell-1eee56a57d3b)
    /// - scrollView.convert(centerView.center, from: centerView.superview)
    /// - Parameter view: 對應的View
    /// - Returns: CGPoint
    func _center(from view: UIView) -> CGPoint {
        
        let centerFromView = convert(view.center, from: view.superview)
        return centerFromView
    }
    
    /// [座標轉換 - 座標點](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用轉換座標的-convert-function-判斷點選的-cell-1eee56a57d3b)
    /// - Parameter view: 對應的View
    /// - Returns: CGPoint
    func _point(from view: UIView) -> CGPoint {
        
        let centerFromView = convert(view.frame.origin, from: view.superview)
        return centerFromView
    }
    
    /// 加上手勢動作功能
    /// - Parameter recognizers: 手勢動作們
    func _addGestureRecognizers(_ recognizers: [UIGestureRecognizer]) {
        recognizers.forEach { (_recognizer) in addGestureRecognizer(_recognizer) }
    }
    
    /// 設定GestureRecognizer (拖曳 / 縮放 / 旋轉)
    /// - Parameter types: Set<Constant.GestureRecognizer>
    func _gestureRecognizerSetting(types: Set<Constant.GestureRecognizer>) {
        if types.contains(.drag) { addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(_dragHandler(_:)))) }
        if types.contains(.scale) { addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(_scaleHandler(_:)))) }
        if types.contains(.rotation) { addGestureRecognizer(UIRotationGestureRecognizer(target: self, action: #selector(_rotationViewHandler(_:)))) }
    }
    
    /// [擷取UIView的畫面](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-uigraphicsimagerenderer-將-view-變成圖片-41d00c568903)
    /// - Parameter afterScreenUpdates: 更新後才擷取嗎？
    /// - Returns: UIImage
    func _screenshot(afterScreenUpdates: Bool = true) -> UIImage {
        
        let render = UIGraphicsImageRenderer(size: self.bounds.size)
        let image = render.image { (_) in drawHierarchy(in: self.bounds, afterScreenUpdates: afterScreenUpdates) }
        
        return image
    }
}

// MARK: - UIView (@objc function)
@objc extension UIView {
    
    /// 移動View (歸零 + 放大的比例也會影響)
    func _dragHandler(_ pan: UIPanGestureRecognizer) {
        
        guard let panLocation = Optional.some(pan.translation(in: self)),
              let view = pan.view
        else {
            return
        }
        
        let newCenter = view.center + panLocation * view.transform.a
        
        view.center = newCenter
        pan.setTranslation(.zero, in: pan.view)
    }
    
    /// 放大View比例 (歸零)
    func _scaleHandler(_ pinch: UIPinchGestureRecognizer) {
        
        guard let view = pinch.view else { return }
        
        if pinch.state == .began || pinch.state == .changed {
            view.transform = view.transform.scaledBy(x: pinch.scale, y: pinch.scale)
            pinch.scale = 1.0
        }
    }
    
    /// 旋轉View (歸零)
    func _rotationViewHandler(_ rotation: UIRotationGestureRecognizer) {
        
        guard let view = rotation.view else { return }
        
        view.transform = view.transform.rotated(by: rotation.rotation)
        rotation.rotation = 0
    }
}

// MARK: - UIVisualEffectView (static function)
extension UIVisualEffectView {
    
    /// [毛玻璃 / 模糊效果](https://www.hangge.com/blog/cache/detail_1135.html)
    /// - Parameters:
    ///   - frame: [CGRect](https://www.jianshu.com/p/a2eb59275aa8)
    ///   - style: [UIBlurEffect.Style](https://nickcarter9.github.io/2016/10/27/2016/2016_10_27-ios-uivibrancyeffect/)
    /// - Returns: [UIView](https://medium.com/jeremy-xue-s-blog/swift-模糊效果-動畫-a96e4957ac8b)
    static func _build(frame: CGRect, style: UIBlurEffect.Style) -> UIVisualEffectView {
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blurView.frame = frame
        
        return blurView
    }
}

// MARK: - UILabel (function)
extension UILabel {
    
    /// 設定系統等寬字型
    /// - Parameter weight: UIFont.Weight
    func _monoSystemFont(weight: UIFont.Weight) {
        font = UIFont._monoSystemFont(ofSize: font.pointSize, weight: weight)
    }
}

// MARK: - CALayer (static function)
extension CALayer {
    
    /// Layer動畫開關
    /// - Parameters:
    ///   - isEnabled: Bool
    ///   - action: () -> Void
    static func _animations(isEnabled: Bool, action: () -> Void) {
        
        CATransaction.begin()
        CATransaction.setDisableActions(!isEnabled)
        
        action()
        
        CATransaction.commit()
    }
}

// MARK: - UIDeviceOrientation
extension UIDeviceOrientation {
    
    /// 畫面方向 => 影片方向
    /// - Returns: UIDeviceOrientation
    func _videoOrientation() -> AVCaptureVideoOrientation? {
        
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .faceUp, .faceDown, .unknown: return .none
        @unknown default: fatalError()
        }
    }
}

// MARK: - PHPhotoLibrary (function)
extension PHPhotoLibrary {
    
    /// 儲存圖片到使用者相簿 - PHPhotoLibrary.shared()
    /// - info.plist => NSPhotoLibraryAddUsageDescription
    /// - Parameters:
    ///   - image: 要儲存的圖片
    ///   - result: Result<Bool, Error>
    func _saveImage(_ image: UIImage?, result: @escaping (Result<Bool, Error>) -> Void) {
        
        guard let image = image else { result(.failure(Constant.MyError.isEmpty)); return }
        
        self.performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { (isSuccess, error) in
            if let error = error { result(.failure(error)); return }
            result(.success(isSuccess))
        })
    }
    
    /// [複製影片到使用者相簿](https://stackoverflow.com/questions/29482738/swift-save-video-from-nsurl-to-user-camera-roll)
    /// - Parameters:
    ///   - url: 要複製的影片URL
    ///   - result: Result<Bool, Error>
    func _saveVideo(at url: URL?, result: @escaping (Result<Bool, Error>) -> Void) {
        
        guard let url = url else {  result(.failure(Constant.MyError.notOpenURL)); return }
        
        self.performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        } completionHandler: { isSuccess, error in
            if let error = error { result(.failure(error)); return }
            result(.success(isSuccess))
        }
    }
}

// MARK: - AVAudioRecorder (static function)
extension AVAudioRecorder {
    
    /// [產生AVAudioRecorder](https://cdfq152313.github.io/post/2016-10-06/)
    /// - Parameters:
    ///   - recordURL: URL
    ///   - format: 聲音壓縮格式
    ///   - audioQuality: 錄音品質
    ///   - bitRate: 音質 (16 bits)
    ///   - channelNumber: 聲道數 (雙聲道)
    ///   - rate: 聲音取樣率 (44100 Hz)
    ///   - delegate: AVAudioRecorderDelegate?
    /// - Returns: Result<AVAudioRecorder, Error>
    static func _build(recordURL: URL, format: AudioFormatID = kAudioFormatMPEG4AAC, audioQuality: AVAudioQuality = .medium, bitRate: Int = 16, channelNumber: Int = 2, rate: Float = 44100.0, delegate: AVAudioRecorderDelegate? = nil) -> Result<AVAudioRecorder, Error> {
        
        let settings: [String: Any] = [
            AVEncoderAudioQualityKey: audioQuality.rawValue,
            AVEncoderBitRateKey: bitRate,
            AVNumberOfChannelsKey: channelNumber,
            AVSampleRateKey: rate
        ]
        
        guard let format = AVAudioFormat(settings: settings) else { return .failure(Constant.MyError.format) }
        
        do {
            let audioRecorder = try AVAudioRecorder(url: recordURL, format: format)
            audioRecorder.delegate = delegate
            return .success(audioRecorder)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - AVAudioRecorder (function)
extension AVAudioRecorder {
    
    /// 開始錄音 (.wav) => NSMicrophoneUsageDescription
    /// - Returns: Result<Bool, Error>
    func _record() -> Result<Bool, Error> {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        }
        catch {
            return .failure(error)
        }
        
        guard self.prepareToRecord(),
              self.record()
        else {
            return .failure(Constant.MyError.isNotRunning)
        }
        
        return .success(true)
    }
    
    /// 停止錄音
    /// - Returns: Result<Bool, Error>
    func _stop() -> Result<Bool, Error> {
        
        self.stop()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            return .failure(error)
        }
        
        return .success(true)
    }
}

// MARK: - AVAudioPlayer (static function)
extension AVAudioPlayer {
    
    /// [產生AVAudioPlayer](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-avplayer-播放-app-裡的-mp3-檔-20c4633c4a03)
    /// - Parameters:
    ///   - audioURL: 音樂檔的路徑
    ///   - fileTypeHint: [音樂檔類型](https://tw.allsaintsetna.org/118500-how-to-play-a-sound-HZPJUV)
    /// - Returns: AVAudioPlayer?
    static func _build(audioURL: URL, fileTypeHint: AVFileType = .mp3, delegate: AVAudioPlayerDelegate? = nil) -> AVAudioPlayer? {
        
        let audioPlayer = try? AVAudioPlayer(contentsOf: audioURL, fileTypeHint: fileTypeHint.rawValue)
        audioPlayer?.delegate = delegate
        
        return audioPlayer
    }
}

// MARK: - AVPlayer (static function)
extension AVPlayer {
    
    /// 產生Player
    /// - 可以加上某一個UIView上面 (定位)
    /// - Parameters:
    ///   - videoURL: 影片的URL
    ///   - baseView: 要貼在哪個View上
    /// - Returns: AVPlayer
    static func _build(videoURL: URL, on baseView: UIView? = nil) -> AVPlayer {
        
        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)

        if let baseView = baseView {
            playerLayer.frame = baseView.bounds
            baseView.layer.addSublayer(playerLayer)
        }
        
        return player
    }
}

// MARK: - AVPlayerViewController (static function)
extension AVPlayerViewController {
    
    /// [產生PlayerController](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-storyboard-的-avplayerviewcontroller-播影片-a717f6428ede)
    /// - Parameters:
    ///   - videoURL: [要播放的URL](https://medium.com/彼得潘的-swift-ios-app-開發教室/29-使用-avplayerviewcontroller-播放影片-e1e055cb62c4)
    ///   - baseView: [要放在哪個View上](https://www.jianshu.com/p/e3c6e0c77b9b)
    ///   - isUpdatesNowPlayingInfoCenter: [要出現在通知欄嗎？](https://stackoverflow.com/questions/41685796/mpnowplayinginfocenter-doesnt-update-any-information-when-after-assigning-to-no)
    /// - Returns: AVPlayerViewController
    static func _build(videoURL: URL, on baseView: UIView? = nil, isUpdatesNowPlayingInfoCenter: Bool = true) -> AVPlayerViewController {
        
        let playerController = AVPlayerViewController()
        let player = AVPlayer._build(videoURL: videoURL, on: baseView)
        
        playerController.player = player
        playerController.updatesNowPlayingInfoCenter = isUpdatesNowPlayingInfoCenter
        
        return playerController
    }
    
    /// 產生PlayerController
    /// - Parameter player: AVPlayer
    /// - Returns: AVPlayerViewController
    static func _build(player: AVPlayer) -> AVPlayerViewController {
        
        let playerController = AVPlayerViewController()
        playerController.player = player
        
        return playerController
    }
}

// MARK: - UIViewController (function)
extension UIViewController {
    
    /// 設定UIViewController透明背景 (當Alert用)
    /// - Present Modally
    /// - Parameter backgroundColor: 背景色
    func _transparent(_ backgroundColor: UIColor = .clear) {
        self._modalStyle(backgroundColor, transitionStyle: .crossDissolve, presentationStyle: .overCurrentContext)
    }
    
    /// [設定UIViewController透明背景 (當Alert用)](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-view-controller-實現-ios-app-的彈出視窗-d1c78563bcde)
    /// - Parameters:
    ///   - backgroundColor: 背景色
    ///   - transitionStyle: 轉場的Style
    ///   - presentationStyle: 彈出的Style
    func _modalStyle(_ backgroundColor: UIColor = .white, transitionStyle: UIModalTransitionStyle = .coverVertical, presentationStyle: UIModalPresentationStyle = .currentContext) {
        self.view.backgroundColor = backgroundColor
        self.modalTransitionStyle = transitionStyle
        self.modalPresentationStyle = presentationStyle
    }
}

// MARK: - UIAlertController (static function)
extension UIAlertController {
    
    /// 選擇用的AlertController (OK / Option1 / Option2)
    /// - Parameters:
    ///   - title: 標題文字
    ///   - message: 內容訊息
    ///   - preferredStyle: 彈出的型式
    ///   - actions: 按下OK的動作
    /// - Returns: UIAlertController
    static func _build(with title: String?, message: String?, preferredStyle: UIAlertController.Style = .alert, actions: [Constant.AlertActionInformation]) -> UIAlertController {
        
        let alertController = _baseAlertController(with: title, message: message, preferredStyle: preferredStyle)
        
        actions.forEach { (info) in
            let action = UIAlertAction(title: info.title, style: info.style) { (_) in if let handler = info.handler { handler() } }
            alertController.addAction(action)
        }
        
        return alertController
    }
}

// MARK: - UIAlertController (private static function)
private extension UIAlertController {
    
    /// AlertController基本型 (僅標題文字)
    /// - Parameters:
    ///   - title: 標題文字
    ///   - message: 內容訊息
    ///   - preferredStyle: 彈出的型式
    /// - Returns: UIAlertController
    static func _baseAlertController(with title: String?, message: String?, preferredStyle: UIAlertController.Style = .alert) -> UIAlertController {
        let alertController = Self(title: title, message: message, preferredStyle: preferredStyle)
        return alertController
    }
}

// MARK: - UIActivityViewController (static function)
extension UIActivityViewController {
    
    /// [產生UIActivityViewController分享功能](https://jjeremy-xue.medium.com/swift-玩玩-uiactivityviewcontroller-5995bb80ff68)
    /// - Parameters:
    ///   - activityItems: [Any]
    ///   - applicationActivities: [UIActivity]?
    ///   - tintColor: tintColor
    ///   - sourceView: 要貼在哪個View上 (for iPad)
    /// - Returns: UIActivityViewController
    static func _build(activityItems: [Any], applicationActivities: [UIActivity]? = nil, tintColor: UIColor = .white, sourceView: UIView? = nil) -> UIActivityViewController {
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        
        activityViewController.view.tintColor = tintColor
        activityViewController.popoverPresentationController?.sourceView = sourceView
        
        return activityViewController
    }
}

// MARK: - UICollectionView (function)
extension UICollectionView {
    
    /// 初始化Protocal
    /// - Parameter this: UICollectionViewDelegate & UICollectionViewDataSource
    func _delegateAndDataSource(with this: UICollectionViewDelegate & UICollectionViewDataSource) {
        self.delegate = this
        self.dataSource = this
    }
    
    /// 取得UICollectionViewCell
    /// - let cell = collectionView._reusableCell(at: indexPath) as MyCollectionViewCell
    /// - Parameter indexPath: IndexPath
    /// - Returns: 符合CellReusable的Cell
    func _reusableCell<T: CellReusable>(at indexPath: IndexPath) -> T where T: UICollectionViewCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.identifier, for: indexPath) as? T else { fatalError("UICollectionViewCell Error") }
        return cell
    }
    
    /// 註冊Cell (使用Class)
    /// - Parameter cellClass: 符合CellReusable的Cell
    func _registerCell<T: CellReusable>(with cellClass: T.Type) { register(cellClass.self, forCellWithReuseIdentifier: cellClass.identifier) }
    
    /// [資料新增或刪除時的動作設定 - performBatchUpdates() => beginUpdates() + endUpdates()](https://ithelp.ithome.com.tw/articles/10225747)
    /// - Parameters:
    ///   - updates: [(() -> Void)?](https://medium.com/@howardsun/uicollectionview-performbatchupdates-最大的秘密-7fb214c81d17)
    ///   - completion: [((Bool) -> Void)?](https://developer.apple.com/documentation/uikit/uicollectionview/1618045-performbatchupdates)
    func _performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        
        self.performBatchUpdates {
            updates?()
        } completion: { isCompleted in
            completion?(isCompleted)
        }
    }
}

// MARK: - UICollectionViewLayout (function)
extension UICollectionViewCompositionalLayout {
            
    func _register(with viewClass: AnyClass?, ofKind kind: WWCompositionalLayout.ReusableSupplementaryViewKind) -> Self {
        self.register(viewClass, forDecorationViewOfKind: "\(kind)")
        return self
    }
}

// MARK: - UIActivityViewController (function)
extension UIActivityViewController {
    
    /// 完成後的結果
    /// - Returns: Result<Bool, Error>
    func _completion() async -> Result<Bool, Error> {
        
        await withCheckedContinuation { continuation in
            self.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if let error = error { continuation.resume(returning: .failure(error)) }
                return continuation.resume(returning: .success(completed))
            }
        }
    }
}

// MARK: - UITapGestureRecognizer (static function)
extension UITapGestureRecognizer {
    
    /// [輕點手勢產生器 (多指)](https://blog.csdn.net/fys_0801/article/details/50605837)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - numberOfTouchesRequired: 需要幾指去點才有反應？
    ///   - numberOfTapsRequired: 需要要點幾下？
    ///   - action: 點下去要做什麼？
    /// - Returns: UITapGestureRecognizer
    static func _build(target: Any?, numberOfTouchesRequired: Int = 1, numberOfTapsRequired: Int = 1, action: Selector?) -> UITapGestureRecognizer {
        
        let recognizer = UITapGestureRecognizer(target: target, action: action)
        
        recognizer.numberOfTapsRequired = numberOfTapsRequired
        recognizer.numberOfTouchesRequired = numberOfTouchesRequired
        
        return recognizer
    }
}

// MARK: - UITapGestureRecognizer (function)
extension UITapGestureRecognizer {
    
    /// 取得點擊畫面位置的百分比
    /// - Returns: CGPoint?
    func _percentPoint() -> CGPoint? {
        
        guard let tapView = view else { return nil }
        
        let point = location(in: tapView)
        let percentPoint = CGPoint(x: point.y / tapView.bounds.height, y: point.x / tapView.bounds.width)
        
        return percentPoint
    }
}

// MARK: - UILongPressGestureRecognizer (static function)
extension UILongPressGestureRecognizer {
    
    /// 長按手勢產生器 (多指)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - numberOfTouchesRequired: 需要幾指去長按才有反應？
    ///   - numberOfTapsRequired: 需要要長按幾下？
    ///   - action: 長按下去要做什麼？
    /// - Returns: UILongPressGestureRecognizer
    static func _build(target: Any?, numberOfTouchesRequired: Int = 1, numberOfTapsRequired: Int = 0, action: Selector?) -> UILongPressGestureRecognizer {
        
        let recognizer = UILongPressGestureRecognizer(target: target, action: action)
        
        recognizer.numberOfTapsRequired = numberOfTapsRequired
        recognizer.numberOfTouchesRequired = numberOfTouchesRequired
        
        return recognizer
    }
}

// MARK: - UIPinchGestureRecognizer (static function)
extension UIPinchGestureRecognizer {
    
    /// 縮放手勢產生器 (多指)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - action: 縮放下去要做什麼？
    /// - Returns: UIPanGestureRecognizer
    static func _build(target: Any?, action: Selector?) -> UIPinchGestureRecognizer {
        
        let recognizer = UIPinchGestureRecognizer(target: target, action: action)
        return recognizer
    }
}

// MARK: - UIPanGestureRecognizer (static function)
extension UIPanGestureRecognizer {
    
    /// 拖曳手勢產生器 (單指)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - action: 拖曳下去要做什麼？
    /// - Returns: UIPanGestureRecognizer
    static func _build(target: Any?, action: Selector?) -> UIPanGestureRecognizer {
        
        let recognizer = UIPanGestureRecognizer(target: target, action: action)
        return recognizer
    }
}

// MARK: - UISwipeGestureRecognizer (static function)
extension UISwipeGestureRecognizer {
    
    /// [滑動手勢產生器 (多指)](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/開發-ios-app-的-gesture-手勢功能-uikit-版本-f6cb95075705)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - direction: 滑動方向
    ///   - number: 需要幾指去滑動才有反應？
    ///   - action: 滑動下去要做什麼？
    /// - Returns: UISwipeGestureRecognizer
    static func _build(target: Any?, direction: UISwipeGestureRecognizer.Direction, numberOfTouches number: Int = 1, action: Selector?) -> UISwipeGestureRecognizer {
        
        let recognizer = UISwipeGestureRecognizer(target: target, action: action)
        
        recognizer.direction = direction
        recognizer.numberOfTouchesRequired = number

        return recognizer
    }
    
    /// 滑動手勢產生器 (多指)
    /// - Parameters:
    ///   - target: 要設定的位置
    ///   - directions: 滑動方向
    ///   - number: 需要幾指去滑動才有反應？
    ///   - action: 滑動下去要做什麼？
    /// - Returns: UISwipeGestureRecognizer
    static func _build(target: Any?, directions: [UISwipeGestureRecognizer.Direction], numberOfTouches number: Int = 1, action: Selector?) -> [UISwipeGestureRecognizer] {
        return directions.map { _build(target: target, direction: $0, numberOfTouches: number, action: action) }
    }
}

// MARK: - AVCaptureDevice (static function)
extension AVCaptureDevice {
    
    /// 取得預設影音裝置 (NSCameraUsageDescription / NSMicrophoneUsageDescription)
    static func _default(for type: AVMediaType) -> AVCaptureDevice? { return AVCaptureDevice.default(for: type) }
    
    /// [取得該選項的影音裝置](https://www.wwdcnotes.com/notes/wwdc19/249/)
    /// - Parameters:
    ///   - deviceType: [AVCaptureDevice.DeviceType](https://blog.csdn.net/u011686167/article/details/130795604)
    ///   - mediaType: AVMediaType?
    ///   - position: AVCaptureDevice.Position
    /// - Returns: AVCaptureDevice?
    static func _default(_ deviceType: AVCaptureDevice.DeviceType, for mediaType: AVMediaType?, position: AVCaptureDevice.Position) -> AVCaptureDevice? { return AVCaptureDevice.default(deviceType, for: mediaType, position: position) }
    
    /// 取得自拍相機 (前)
    /// - Returns: AVCaptureDevice?
    static func _selfieCamera() -> AVCaptureDevice? {
        
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices
        return devices.first
    }
    
    /// 搜尋影音裝置
    /// - Parameters:
    ///   - deviceTypes: [AVCaptureDevice.DeviceType]
    ///   - mediaType: AVMediaType?
    ///   - position: AVCaptureDevice.Position
    /// - Returns: [AVCaptureDevice]
    static func _discovery(deviceTypes: [AVCaptureDevice.DeviceType], mediaType: AVMediaType?, position: AVCaptureDevice.Position) -> [AVCaptureDevice] {
        
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: position).devices
        return devices
    }
    
    /// 取得廣角相機 (後)
    /// - Returns: AVCaptureDevice?
    static func _wideAngleCamera() -> AVCaptureDevice? {
        
        let devices = AVCaptureDevice._discovery(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
        return devices.first
    }
    
    /// 取得超廣角相機 (後)
    /// - Returns: AVCaptureDevice?
    static func _ultraWideCamera() -> AVCaptureDevice? {
        
        let devices = AVCaptureDevice._discovery(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .back)
        return devices.first
    }
}

// MARK: - AVCaptureDevice (function)
extension AVCaptureDevice {
    
    /// 判斷鏡頭的位置 (前後) => .front / .back
    func _videoPosition() -> AVCaptureDevice.Position { return self.position }
    
    /// 取得裝置的Input => NSCameraUsageDescription / NSMicrophoneUsageDescription
    func _captureInput() -> Result<AVCaptureDeviceInput, Error> {
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: self)
            return .success(deviceInput)
        } catch {
            return .failure(error)
        }
    }
    
    /// [取得該裝置作用的硬體參數值](https://developer.apple.com/documentation/avfoundation/avcapturedevice/format)
    /// - Returns: AVCaptureDevice.Format
    func _format() -> AVCaptureDevice.Format { return activeFormat }
    
    /// 取得該裝置可用的硬體參數值
    /// - Returns: [AVCaptureDevice.Format]
    func _formats() -> [AVCaptureDevice.Format] { return formats }
    
    /// [取得該裝置特定解析度的硬體參數值](https://medium.com/snapp-mobile/step-by-step-tutorial-configuring-session-for-60fps-video-capture-cf7d5d000ba3)
    /// - Parameter definition: Constant.VideoSize
    /// - Returns: [AVCaptureDevice.Format]
    func _formats(videoSize: Constant.VideoSize) -> [AVCaptureDevice.Format] {
        
        let formats = _formats().filter { format in
            let dimensions = format.formatDescription.dimensions
            return dimensions.width == videoSize.width && dimensions.height == videoSize.height
        }
                
        return formats
    }
    
    /// 取得該裝置特定解析度的硬體參數值
    /// - Parameter definition: Constant.VideoDefinition
    /// - Returns: [AVCaptureDevice.Format]
    func _formats(definition: Constant.VideoDefinition) -> [AVCaptureDevice.Format] {
        return _formats(videoSize: definition.size(for: .right))
    }
    
    /// 鏡頭縮放
    /// - Parameters:
    ///   - rate: 比率
    ///   - factor: 倍率因子
    ///   - isSmooth: 是否要平滑縮放？
    /// - Returns: Result<Bool, Error>
    func _zoom(with rate: CGFloat, factor: CGFloat, isSmooth: Bool = false) -> Result<CGFloat?, Error> {
        let range: ClosedRange<Double> = minAvailableVideoZoomFactor...maxAvailableVideoZoomFactor
        return _zoom(rate: rate, factor: factor, isSmooth: isSmooth, range: range)
    }
    
    /// [鏡頭縮放](https://developer.apple.com/documentation/avfoundation/avcapturedevice/1624614-ramp)
    /// - Parameters:
    ///   - rate: [比率](https://blog.csdn.net/u012581760/article/details/80936741)
    ///   - factor: [倍率因子](https://stackoverflow.com/questions/45227163/using-avcapturedevice-zoom-settings)
    ///   - isSmooth: [是否要平滑縮放？](https://stackoverflow.com/questions/33180564/pinch-to-zoom-camera)
    ///   - range: 自訂的比例區間
    /// - Returns: Result<Bool, Error>
    func _zoom(rate: CGFloat, factor: CGFloat, isSmooth: Bool = false, range: ClosedRange<Double>) -> Result<CGFloat?, Error> {
        
        let maxZoomFactor = min(maxAvailableVideoZoomFactor, CGFloat(range.upperBound))
        let minZoomFactor = max(minAvailableVideoZoomFactor, CGFloat(range.lowerBound))
        
        if (factor > maxZoomFactor) { return .failure(Constant.MyError.isTooLarge) }
        if (factor < minZoomFactor) { return .failure(Constant.MyError.isTooSmall) }
        
        return _lockForConfiguration { () -> CGFloat? in
            
            if (isSmooth) {
                self.ramp(toVideoZoomFactor: factor, withRate: Float(rate))
            } else {
                self.videoZoomFactor = factor
            }
            
            return self.videoZoomFactor
        }
    }
        
    /// [設定手電筒模式](https://ithelp.ithome.com.tw/articles/10236699)
    /// - Parameter mode: [AVCaptureDevice.TorchMode](https://developer.apple.com/documentation/avfoundation/avcapturedevice/1386035-torchmode)
    /// - Returns: Result<AVCaptureDevice.TorchMode, Error>
    func _torchMode(_ mode: AVCaptureDevice.TorchMode = .auto) -> Result<AVCaptureDevice.TorchMode, Error> {
        
        if (!hasTorch) { return .failure(Constant.MyError.noTorch) }
        
        return _lockForConfiguration { () -> AVCaptureDevice.TorchMode in
            self.torchMode = mode
            return self.torchMode
        }
    }
    
    /// [設定影像的解析度](https://cloud.tencent.com/developer/ask/sof/108419727/answer/119356889)
    /// - Parameters:
    ///   - activeFormat: AVCaptureDevice.Format
    ///   - defaultFPS: Float64
    /// - Returns: Result<Float64, Error>
    func _activeFormat(_ activeFormat: AVCaptureDevice.Format, defaultFPS: Float64 = 30) -> Result<Float64, Error> {
        
        return _lockForConfiguration { () -> Float64 in
            
            let maxFrameRate = activeFormat.videoSupportedFrameRateRanges.max { $0.maxFrameRate < $1.maxFrameRate }?.maxFrameRate ?? defaultFPS
            
            self.activeFormat = activeFormat
            self.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(maxFrameRate))
            self.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(maxFrameRate))
            
            return maxFrameRate
        }
    }
    
    /// 設定相機對焦模式
    /// - Parameters:
    ///   - focusMode: 對焦模式
    ///   - point: 相機對焦點 => CGPoint(x: 0.5, y: 0.5)
    /// - Returns: Result<Bool, Error>
    func _focusMode(_ focusMode: AVCaptureDevice.FocusMode, point: CGPoint?) -> Result<Bool, Error> {
        
        if (!isFocusModeSupported(focusMode)) { return .success(false) }
        
        return _lockForConfiguration {
            
            self.focusMode = focusMode
            if let point = point { self.focusPointOfInterest = point }
            
            return true
        }
    }
    
    /// [設定相機的白平衡模式](https://kanchuan.com/blog/120-ios-white-balance)
    /// - Parameter whiteBalanceMode: [WhiteBalanceMode](https://www.fotobeginner.com/44/introduction-to-white-balance-part-1/)
    /// - Returns: [Result<Bool, Error>](https://blog.csdn.net/yp476984646/article/details/100519949)
    func _whiteBalanceMode(_ whiteBalanceMode: WhiteBalanceMode) -> Result<Bool, Error> {
        
        return _lockForConfiguration {
            self.whiteBalanceMode = whiteBalanceMode
            return true
        }
    }
}

// MARK: - AVCaptureDevice (function)
private extension AVCaptureDevice {
    
    /// [lock住設備 => 硬體參數設定](https://objccn.io/issue-23-1/)
    /// - Returns: Result<T, Error>
    func _lockForConfiguration<T>(_ block: @escaping (() -> T)) -> Result<T, Error> {
        
        defer { unlockForConfiguration() }
        
        do {
            try lockForConfiguration()
            return .success(block())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - AVCapturePhotoOutput (function)
extension AVCapturePhotoOutput {
    
    /// 擷圖 => 拍照 => photoOutput(_:didFinishProcessingPhoto:error:)
    /// - Parameters:
    ///   - isHighResolutionPhotoEnabled: 高解析度
    ///   - flashMode: 閃光燈 => 自動
    ///   - delegate: AVCapturePhotoCaptureDelegate
    ///   - completion: (() -> Void)?
    func _capturePhoto(isHighResolutionPhotoEnabled: Bool = true, flashMode: AVCaptureDevice.FlashMode, delegate: AVCapturePhotoCaptureDelegate, completion: (() -> Void)? = nil) {
        
        self.isHighResolutionCaptureEnabled = isHighResolutionPhotoEnabled
        
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isHighResolutionPhotoEnabled = isHighResolutionPhotoEnabled
        photoSettings.flashMode = flashMode
        
        capturePhoto(with: photoSettings, delegate: delegate)
        
        completion?()
    }
    
    /// [基本參數設定](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app)
    /// - Parameters:
    ///   - isHighResolutionPhotoEnabled: 高解析度
    ///   - quality: 拍照品質
    func _setting(isHighResolutionPhotoEnabled: Bool = true, quality: AVCapturePhotoOutput.QualityPrioritization) -> Self {
        
        isHighResolutionCaptureEnabled = isHighResolutionPhotoEnabled
        maxPhotoQualityPrioritization = quality
        
        return self
    }
}

// MARK: - AVCaptureSession (function)
extension AVCaptureSession {
    
    /// 設定硬體
    /// - Parameter action: () -> Void
    /// - Returns: T
    func _configuration<T>(action: () -> T) -> T {
        
        beginConfiguration()
        defer { commitConfiguration() }
        
        return action()
    }
    
    /// 換掉鏡頭 (isRunning才會換)
    /// - Parameters:
    ///   - camera: AVCaptureDevice
    ///   - position: AVCaptureDevice.Position
    /// - Returns: Result<Bool, Error>
    func _changeCamera(_ camera: AVCaptureDevice, position: AVCaptureDevice.Position) -> Result<Bool, Error> {
        
        guard isRunning else { return .failure(Constant.MyError.isNotRunning) }
        
        return _configuration {
            
            var result: Result<Bool, Error> = .failure(Constant.MyError.isEmpty)
            
            for input in inputs {
                
                guard let input = input as? AVCaptureDeviceInput,
                      input.device.position == position
                else {
                    continue
                }
                
                _removeInputs([input])
                result = _canAddDevice(camera, isConnections: true)
            }
            
            return result
        }
    }
    
    /// 清除[AVCaptureInput]
    func _removeInputs(_ inputs: [AVCaptureInput]) {
        for input in inputs { self.removeInput(input) }
    }
    
    /// 加入手機設備 (相機、麥克風…)
    /// - Parameters:
    ///   - device: AVCaptureDevice
    ///   - isConnections: Bool
    /// - Returns: Result<Bool, Error>
    func _canAddDevice(_ device: AVCaptureDevice, isConnections: Bool) -> Result<Bool, Error> {
        
        switch device._captureInput() {
        case .failure(let error): return .failure(error)
        case .success(let input): return .success(_canAddInput(input, isConnections: isConnections))
        }
    }
    
    /// 將影音的Input加入Session (可以不連接)
    /// - Parameters:
    ///   - input: AVCaptureInput?
    ///   - isConnections: [Bool](https://www.cnblogs.com/zouchenxi/p/14900858.html)
    /// - Returns: Bool
    func _canAddInput(_ input: AVCaptureInput?, isConnections: Bool) -> Bool {
        
        guard let input = input,
              canAddInput(input)
        else {
            return false
        }
        
        (isConnections) ? addInput(input) : addInputWithNoConnections(input)
        return true
    }
    
    /// 將影音的Output加入Session (可以不連接)
    /// - Parameters:
    ///   - output: AVCaptureOutput?
    ///   - isConnections: Bool
    /// - Returns: Bool
    func _canAddOutput(_ output: AVCaptureOutput?, isConnections: Bool) -> Bool {
        
        guard let output = output,
              canAddOutput(output)
        else {
            return false
        }
        
        (isConnections) ? addOutput(output) : addOutputWithNoConnections(output)
        return true
    }
}

// MARK: - AVCapturePhoto (function)
extension AVCapturePhoto {
    
    /// AVCapturePhoto => Data
    /// - Returns: Data?
    func _fileData() -> Data? { return fileDataRepresentation() }
    
    /// AVCapturePhoto => UIImage
    /// - Parameter scale: CGFloat
    /// - Returns: UIImage?
    func _image(scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        guard let imageData = self._fileData() else { return nil }
        return UIImage(data: imageData, scale: scale)
    }
    
    /// AVCapturePhoto => CIImage
    /// - Returns: CIImage
    func _ciImage() -> CIImage? {
        guard let imageData = self._fileData() else { return nil }
        return CIImage(data: imageData)
    }
}

// MARK: - AVCaptureConnection (function)
extension AVCaptureConnection {
    
    /// 設定鏡頭影片鏡射 => 前鏡頭的影像是左右相反的
    /// - Returns: Bool
    func _videoMirror(_ isMirrored: Bool) -> Bool {
        if (isVideoMirroringSupported) { isVideoMirrored = isMirrored }
        return isVideoMirroringSupported
    }
}

// MARK: - AVFileType (function)
extension AVFileType {
    
    /// 取得相對應的副檔名
    /// - Returns: String
    func _extension() -> String {

        var `extension`: String = ""
        
        switch self {
        case .mov: `extension` = ".mov"             // com.apple.quicktime-movie            (.qt, .mov)
        case .mp4: `extension` = ".mp4"             // public.mpeg-4                        (.mp4)
        case .m4v: `extension` = ".m4v"             // com.apple.m4v-video                  (.m4v)
        case .m4a: `extension` = ".m4a"             // com.apple.m4a-audio                  (.m4a)
        case .mobile3GPP: `extension` = ".3gp"      // public.3gpp                          (.3gp, .3gpp, .sdv)
        case .mobile3GPP2: `extension` = ".3gp2"    // public.3gpp2                         (.3g2, .3gp2)
        case .caf: `extension` = ".caf"             // com.apple.coreaudio-format           (.caf)
        case .wav: `extension` = ".wav"             // com.microsoft.waveform-audio         (.wav, .wave, .bwf)
        case .aiff: `extension` = ".aiff"           // public.aiff-audio                    (.aif, .aiff)
        case .aifc: `extension` = ".aifc"           // public.aifc-audio                    (.aifc, .cdda)
        case .amr: `extension` = ".amr"             // org.3gpp.adaptive-multi-rate-audio   (.amr)
        case .mp3: `extension` = ".mp3"             // public.mp3                           (.mp3)
        case .au: `extension` = ".au"               // public.au-audio                      (.au and .snd)
        case .ac3: `extension` = ".ac3"             // public.ac3-audio                     (.ac3)
        case .eac3: `extension` = ".eac3"           // public.enhanced-ac3-audio            (.eac3)
        case .jpg: `extension` = ".jpg"             // public.jpeg                          (.jpg or .jpeg)
        case .dng: `extension` = ".dng"             // com.adobe.raw-image                  (.dng)
        case .heic: `extension` = ".heic"           // public.heic                          (.heic)
        case .avci: `extension` = ".avci"           // public.avci                          (.avci)
        case .heif: `extension` = ".heif"           // public.heif                          (.heif)
        case .tif: `extension` = ".tif"             // public.tiff                          (.tiff, .tif)
        // case .AHAP: `extension` = ".ahap"           // public.haptics-content               (.ahap)
        default: break
        }
        
        return `extension`
    }
}

// MARK: - AVAsset (static function)
extension AVAsset {
    
    /// 產生AVAsset
    /// - Parameter url: URL
    /// - Returns: AVAsset
    static func _build(url: URL) -> AVAsset {
        return AVAsset(url: url)
    }
}

// MARK: - AVAsset (function)
@available(iOS 15, *)
extension AVAsset {
    
    /// 讀取相關資訊
    /// - Parameter property: AVAsyncProperty<AVAsset, T>
    /// - Returns: Result<T, Error>
    func _load<T>(property: AVAsyncProperty<AVAsset, T>) async -> Result<T, Error> {
        
        do {
            let value = try await load(property)
            return .success(value)
        } catch {
            return .failure(error)
        }
    }
    
    /// 讀取音軌 / 影片軌道
    /// - Parameters:
    ///   - mediaType: AVMediaType
    ///   - result: (Result<[AVAssetTrack]?, Error>) -> Void
    func _loadTracks(mediaType: AVMediaType, result: @escaping ((Result<[AVAssetTrack]?, Error>) -> Void)) {
        
        loadTracks(withMediaType: mediaType) { tracks, error in
            if let error = error { result(.failure(error)); return }
            result(.success(tracks))
        }
    }
    
    /// 讀取音軌 / 影片軌道
    /// - Parameter mediaType: AVMediaType
    /// - Returns: Result<[AVAssetTrack]?, Error>
    func _loadTracks(mediaType: AVMediaType) async -> Result<[AVAssetTrack]?, Error> {
        
        await withCheckedContinuation { continuation in
            _loadTracks(mediaType: mediaType) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    /// 取得週期相關的數據
    /// - Returns: Result<CMTime?, Error>
    func _duration() async -> Result<CMTime, Error> {
        return await _load(property: .duration)
    }
    
    /// 取得影片長度 (秒數)
    /// - Returns: Result<Double?, Error>
    func _seconds() async -> Result<Double?, Error> {
        
        let result = await _duration()
        
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let duration): return .success(duration.seconds)
        }
    }
    
    /// 取得影片資料軌道 => 解析度 (naturalSize) / 幀率 (nominalFrameRate)
    /// - Parameter index: 第幾軌
    /// - Returns: AVAssetTrack?
    func _videoTrack(index: Int = 0) async -> AVAssetTrack? {
        return try? await _loadTracks(mediaType: .video).get()?[safe: index]
    }
}

// MARK: - AVAssetTrack (function)
@available(iOS 15, *)
extension AVAssetTrack {
    
    /// 讀取相關資訊
    /// - Parameter property: AVAsyncProperty<AVAsset, T>
    /// - Returns: Result<T, Error>
    func _load<T>(property: AVAsyncProperty<AVAssetTrack, T>) async -> Result<T, Error> {
        
        do {
            let value = try await load(property)
            return .success(value)
        } catch {
            return .failure(error)
        }
    }
    
    /// 取得影片尺寸 => 1920 x 1080
    /// - Returns: Result<CGSize, Error>
    func _size() async -> Result<CGSize, Error> {
        return await _load(property: .naturalSize)
    }
    
    /// 取得影片資料幀率 => FPS（Frames Per Second）
    /// - Returns: Result<Float, Error>
    func _fps() async -> Result<Float, Error> {
        return await _load(property: .nominalFrameRate)
    }
}

// MARK: - AVAssetWriter (function)
extension AVAssetWriter {
    
    /// [建立AVAssetWriter](https://juejin.cn/post/7159531544413995044)
    /// - Parameters:
    ///   - outputURL: [URL?](https://juejin.cn/post/7159149701143461896)
    ///   - fileType: AVFileType
    /// - Returns: Result<AVAssetWriter, Error>
    static func _build(outputURL: URL?, fileType: AVFileType) -> Result<AVAssetWriter, Error> {
        
        guard let outputURL = outputURL else { return .failure(Constant.MyError.isEmpty) }
        
        do {
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: fileType)
            return .success(writer)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - AVAssetWriterInput (function)
extension AVAssetWriter {
    
    /// 啟動Session
    /// - Parameters:
    ///   - startTime: CMTime
    ///   - action: () -> Void
    func _startSession(at startTime: CMTime, action: () -> Void) {
        startSession(atSourceTime: startTime)
        action()
    }
    
    /// 加入Input
    /// - Parameter input: AVAssetWriterInput?
    /// - Returns: Bool
    func _canAdd(input: AVAssetWriterInput?) -> Bool {
        
        guard let input = input,
              canAdd(input)
        else {
            return false
        }
        
        add(input)
        return true
    }
}

// MARK: - AVAssetWriterInput (static function)
extension AVAssetWriterInput {
    
    /// [建立AVAssetWriterInput](https://www.cnblogs.com/zoule/p/14913203.html)
    /// - Parameters:
    ///   - mediaType: AVMediaType
    ///   - outputSettings: outputSettings
    ///   - sourceFormatHint: sourceFormatHint
    ///   - isExpectsMediaDataInRealTime: Bool
    /// - Returns: AVAssetWriterInput
    static func _build(mediaType: AVMediaType, outputSettings: [String: Any]?, sourceFormatHint: CMFormatDescription?, isExpectsMediaDataInRealTime: Bool) -> AVAssetWriterInput {
        
        let input = AVAssetWriterInput(mediaType: mediaType, outputSettings: outputSettings, sourceFormatHint: sourceFormatHint)
        input.expectsMediaDataInRealTime = isExpectsMediaDataInRealTime
        
        return input
    }
    
    /// [建立影片AVAssetWriterInput](https://juejin.cn/post/6844903929252151304)
    /// - Parameters:
    ///   - size: 影片尺寸大小
    ///   - codec: 影片編碼格式
    ///   - sourceFormatHint: CMFormatDescription?
    ///   - isExpectsMediaDataInRealTime: 針對即時性進行最佳化
    /// - Returns: AVAssetWriterInput
    static func _buildVideo(size: Constant.VideoSize, codec: AVVideoCodecType, sourceFormatHint: CMFormatDescription? = nil, isExpectsMediaDataInRealTime: Bool = true) -> AVAssetWriterInput {
        
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        
        return Self._build(mediaType: .video, outputSettings: outputSettings, sourceFormatHint: sourceFormatHint, isExpectsMediaDataInRealTime: isExpectsMediaDataInRealTime)
    }
    
    /// 建立聲音AVAssetWriterInput
    /// - Parameters:
    ///   - format: 音頻格式 (kAudioFormatMPEG4AAC / kAudioFormatMPEGLayer3)
    ///   - channels: 通道數 (單聲道 / 雙聲道)
    ///   - sampleRate: 頻率取樣 (Hz)
    ///   - bitRate: 比特率 / 取樣率 (bps)
    ///   - sourceFormatHint: CMFormatDescription?
    ///   - isExpectsMediaDataInRealTime: 針對即時性進行最佳化
    /// - Returns: AVAssetWriterInput
    static func _buildAudio(format: AudioFormatID, channels: Int = 2, sampleRate: Int = 44100, bitRate: Int = 64000, sourceFormatHint: CMFormatDescription? = nil, isExpectsMediaDataInRealTime: Bool = true) -> AVAssetWriterInput {
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: format,
            AVNumberOfChannelsKey: channels,
            AVSampleRateKey: sampleRate,
            AVEncoderBitRateKey: bitRate
        ]
        
        return Self._build(mediaType: .audio, outputSettings: outputSettings, sourceFormatHint: sourceFormatHint, isExpectsMediaDataInRealTime: isExpectsMediaDataInRealTime)
    }
}

// MARK: - AVCaptureVideoDataOutput (function)
extension AVCaptureVideoDataOutput {
    
    /// [設定影片的輸出方向](https://www.codenong.com/3823461/)
    /// - Parameter orientation: [AVCaptureVideoOrientation](https://medium.com/onfido-tech/live-face-tracking-on-ios-using-vision-framework-adf8a1799233)
    /// - Returns: Bool
    func _videoOrientation(_ orientation: AVCaptureVideoOrientation) -> Bool {
        
        guard let connection = connection(with: .video),
              connection.isVideoOrientationSupported
        else {
            return false
        }

        connection.videoOrientation = orientation
        return true
    }
}

// MARK: - AVCaptureVideoOrientation
extension AVCaptureVideoOrientation {
    
    /// 影片方向 => 畫面方向
    /// - Returns: UIDeviceOrientation
    func _screenOrientation() -> UIDeviceOrientation {
        
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        @unknown default: fatalError()
        }
    }
}

// MARK: - AVAssetWriterInputPixelBufferAdaptor (function)
extension AVAssetWriterInputPixelBufferAdaptor {
    
    /// [建立AVAssetWriterInputPixelBufferAdaptor](https://juejin.cn/post/6844904115416334350)
    /// - Parameters:
    ///   - videoWriterInput: AVAssetWriterInput?
    ///   - vedioSize: 影片尺寸
    ///   - pixelFormat: 像素格式
    static func _build(videoWriterInput: AVAssetWriterInput?, vedioSize: Constant.VideoSize, pixelFormat: OSType = kCVPixelFormatType_32BGRA) -> AVAssetWriterInputPixelBufferAdaptor? {
        
        guard let videoWriterInput = videoWriterInput else { return nil }
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(pixelFormat),
                kCVPixelBufferWidthKey as String: vedioSize.width,
                kCVPixelBufferHeightKey as String: vedioSize.height
            ]
        )
        
        return adaptor
    }
}

// MARK: - CMSampleBuffer
extension CMSampleBuffer {
    
    /// [CMSampleBuffer => CIImage](https://rethunk.medium.com/cmsamplebuffer-to-uiimage-in-swift-5bf96d393d5e)
    /// - [captureOutput(_:didOutput:from:)](https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutputsamplebufferdelegate/1385775-captureoutput)
    /// - Returns: [CIImage?](https://developer.apple.com/documentation/coremedia/cmsamplebuffer-u71)
    func _ciImage() -> CIImage? {
        guard let imageBuffer = imageBuffer else { return nil }
        return CIImage(cvImageBuffer: imageBuffer)
    }
}

// MARK: - CIFilter (static function)
extension CIFilter {
    
    /// [產生CIFilter](https://blog.csdn.net/qq_22981537/article/details/52487074)
    /// - Parameters:
    ///   - key: Constant.CIFilterKey
    ///   - parameters: [String: Any]
    /// - Returns: CIFilter?
    static func _build(with key: Constant.CIFilterKey, parameters: [String: Any] = [:]) -> CIFilter? {
        return Self._build(with: key.rawValue, parameters: parameters)
    }
    
    /// 產生CIFilter
    /// - Parameters:
    ///   - key: String => kCIInputImageKey…
    ///   - parameters: [String: Any]
    /// - Returns: CIFilter?
    static func _build(with name: String, parameters: [String: Any] = [:]) -> CIFilter? {
        return CIFilter(name: name, parameters: parameters)
    }
    
    /// 使用濾鏡疊加圖片 (子母畫面形式)
    /// - Parameters:
    ///   - mainImage: CIImage
    ///   - pipImage: CIImage
    /// - Returns: CIImage?
    static func _combine(sourceOverCompositing mainImage: CIImage?, pipImage: CIImage?) -> CIImage? {
        
        guard let mainImage = mainImage,
              let pipImage = pipImage
        else {
            return nil
        }
        
        let parameters = [
            kCIInputBackgroundImageKey: mainImage,
            kCIInputImageKey: pipImage
        ]
        
        guard let filter = CIFilter._build(with: .sourceOverCompositing, parameters: parameters) else { return nil }
        
        return filter.outputImage
    }
}

// MARK: - CVPixelBuffer (static function)
extension CVPixelBuffer {
    
    /// 建立在緩衝池上的CVPixelBuffer
    /// - Parameter pixelBufferPool: CVPixelBufferPool?
    /// - Returns: CVPixelBuffer?
    static func _build(pixelBufferPool: CVPixelBufferPool?) -> CVPixelBuffer? {
        
        guard let pixelBufferPool = pixelBufferPool else { return nil }
        
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
        
        return pixelBuffer
    }
    
    /// 處理PIP影像圖片的尺寸大小 (對應主影像圖片)
    /// - Parameters:
    ///   - pipBuffer: CVPixelBuffer
    ///   - pipImageframe: CGRect
    ///   - mainBuffer: CVPixelBuffer
    /// - Returns: CIImage
    static func _transformPipImage(with pipBuffer: CVPixelBuffer, pipImageFrame: CGRect, for mainBuffer: CVPixelBuffer) -> CIImage {
        
        let pipCIImage = pipBuffer._ciImage()
        let scaleX = pipImageFrame.width / pipBuffer._size().width
        let scaleY = pipImageFrame.height / pipBuffer._size().height
        
        let pipTransform = CGAffineTransform(translationX: pipImageFrame.minX, y: pipImageFrame.minY).scaledBy(x: scaleX, y: scaleY)
        let transformedPipImage = pipCIImage.transformed(by: pipTransform)
        
        return transformedPipImage
    }
}

// MARK: - CVPixelBuffer (function)
extension CVPixelBuffer {
    
    /// CVPixelBuffer => CIImage
    /// - Returns: CIImage
    func _ciImage() -> CIImage {
        return CIImage(cvPixelBuffer: self)
    }
    
    /// 取得CVPixelBuffer的尺寸大小
    /// - Returns: CGSize
    func _size() -> CGSize {
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        return CGSize(width: width, height: height)
    }
    
    /// 處理PIP影像圖片的尺寸大小 (對應主影像圖片)
    /// - Parameters:
    ///   - buffer: CVPixelBuffer
    ///   - imageFrame: CGRect
    /// - Returns: CIImage
    func _transformPipImage(buffer: CVPixelBuffer, imageFrame: CGRect) -> CIImage {
        return Self._transformPipImage(with: buffer, pipImageFrame: imageFrame, for: self)
    }
}

// MARK: - CVPixelBufferPool (static function)
extension CVPixelBufferPool {
    
    /// [建立緩衝池](https://cloud.tencent.com/developer/ask/sof/115665619)
    /// - Parameters:
    ///   - minimumBufferCount: 最少幾個？
    ///   - format: 圖片顏色編碼
    ///   - videoSize: 影片大小
    ///   - properties: 其它特性
    /// - Returns: CVPixelBufferPool
    static func _build(minimumBufferCount: Int, format: OSType = kCVPixelFormatType_32BGRA, videoSize: Constant.VideoSize, properties: [String: Any] = [:]) -> CVPixelBufferPool {
        
        var pixelBufferPool: CVPixelBufferPool!
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey: minimumBufferCount]
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: format,
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height,
            kCVPixelBufferIOSurfacePropertiesKey as String: properties
        ]
        
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as CFDictionary, pixelBufferAttributes as CFDictionary, &pixelBufferPool)
        
        return pixelBufferPool
    }
}

// MARK: - AVAssetImageGenerator (function)
extension AVAssetImageGenerator {
    
    /// [AVPlayerLayer擷圖](https://stackoverflow.com/questions/42020130/swift-how-to-take-screenshot-of-avplayerlayer)
    /// - Parameters:
    ///   - url: [影片的URL](https://www.jianshu.com/p/bf07b0b839cc)
    ///   - time: 第幾秒的影片
    ///   - maximumSize: 擷圖的最大尺寸 => CGSize(width: 0, height: 256)
    /// - Returns: Swift.Result<UIImage?, Error>
    static func _screenshot(url: URL?, time: Float64 = 0, maximumSize: CGSize?) -> Swift.Result<CGImage, Error> {
        
        guard let url = url else { return .failure(Constant.MyError.notOpenURL) }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let time = CMTimeMakeWithSeconds(time, preferredTimescale: 1)
        
        var actualTime = CMTimeMake(value: 0, timescale: 0)
        
        if let maximumSize = maximumSize { imageGenerator.maximumSize = maximumSize }
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
            return .success(cgImage)
        } catch {
            return .failure(error)
        }
    }
}
