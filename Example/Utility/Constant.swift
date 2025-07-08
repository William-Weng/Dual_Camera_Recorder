//
//  Constant.swift
//  Example
//
//  Created by William.Weng on 2024/8/8.
//

import UIKit
import AVFoundation

// MARK: - Constant
final class Constant: NSObject {
    
    static let shared = Constant()
    
    let previewImageSegue = "PreviewImageSegue"
    let previewSegue = "PreviewSegue"
    let audioImage = UIImage(named: "Speaker")
    let albumImage = UIImage(named: "VideoFolder")
    let focusPointOfInterestPoint = CGPoint(x: 0.5, y: 0.5)
    let fileType: (video: AVFileType, audio: AVFileType, image: AVFileType) = (.mov, .m4a, .jpg)
    let imageCompressionQuality = 0.8
    let focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus
    let folderType: Constant.FileManagerDirectoryType = .temporary
    let autoZoomScheduledSecond: TimeInterval = 2.5
    let minimumVideoBufferPoolCount = 3
    
    private override init() {}
}

// MARK: - typealias
extension Constant {
    
    typealias AlertActionInformation = (title: String?, style: UIAlertAction.Style, handler: (() -> Void)?)                                 // UIAlertController的按鍵相關資訊
    typealias VideoSize = (width: Int, height: Int)                                                                                         // 影片的尺寸 (寬 / 高)
    typealias ScreenBoundsInformation = (width: CGFloat, height: CGFloat, scale: CGFloat)                                                   // iPhone的裝置螢幕大小 (寬/高/比例)
    typealias CameraInputs = (main: CameraInput?, mainTemp: CameraInput?, pip: CameraInput?)                                                // 主鏡頭 (廣角) / PIP鏡頭 / 主鏡頭 (超廣角)
    typealias FileInformation = (isExist: Bool, isDirectory: Bool)                                                                          // 檔案相關資訊 (是否存在 / 是否為資料夾)
    typealias VideoDataOutputs = (back: AVCaptureVideoDataOutput?, backTemp: AVCaptureVideoDataOutput?, front: AVCaptureVideoDataOutput?)   // 影片資訊 (前後鏡頭)
    typealias CameraInput = (device: AVCaptureDevice?, definition: Constant.VideoDefinition)                                                // 影片輸入 (設備 / 解析度)
    typealias ScreenOrientation = (current: UIDeviceOrientation, item: UIImage.Orientation)                                                 // 手機畫面的方向 (一般時 / 圖示)
    typealias CameraZoomFactor = (main: Double, mainTemp: Double, pip: Double)                                                              // 鏡頭縮放比例 => 主鏡頭 (廣角) / PIP鏡頭 / 主鏡頭
}

// MARK: - enum
extension Constant {
    
    /// [CIFilter](https://medium.com/彼得潘的試煉-勇者的-100-道-swift-ios-app-謎題/74-利用-cifilter-實現美麗的圖片濾鏡-6b7323612188)
    enum CIFilterKey: String {
        case sourceOverCompositing = "CISourceOverCompositing"          // 使用疊加模式來組合源圖像和背景圖像
        case roundedRectangleGenerator = "CIRoundedRectangleGenerator"  // 指定尺寸和圓角半徑的矩形圖像
        case sourceInCompositing = "CISourceInCompositing"              // 只保留源圖像中與背景圖像重疊且背景圖像不透明的部分 (遮罩)
    }
    
    /// [手勢的動作](https://itisjoe.gitbooks.io/swiftgo/content/uikit/uigesturerecognizer.html)
    enum GestureRecognizer {
        case drag
        case scale
        case rotation
    }
    
    /// 小鏡頭Layer的外形
    enum PipLayerStyle {
        case circle                                                         // 圓形
        case square(cornerRadius: CGFloat = 8.0)                            // 正方形
        case rectangle(scale: CGFloat = 0.5, cornerRadius: CGFloat = 8.0)   // 長方形
    }
    
    /// 顯示影像View的編號
    enum CameraViewTag: Int {
        case main = 1001
        case mainTemp = 1002
        case pip = 2001
    }
    
    /// 自定義訊息文字
    enum Message {
        
        case error
        case reminder
        case deleteImage
        case deleteFile
        case deleteFiles
        case stopRecording
        
        /// 文字輸出
        /// - Returns: String
        func output() -> String {
            
            switch self {
            case .error: return "Error"
            case .reminder: return "Reminder"
            case .deleteImage: return "Do you really want to delete this image?"
            case .deleteFile: return "Do you really want to delete this file?"
            case .deleteFiles: return "Do you really want to delete these files?"
            case .stopRecording: return "Are you sure you want to stop recording?"
            }
        }
    }
    
    /// 自訂錯誤
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }
        
        case unknown
        case isTooLarge
        case isTooSmall
        case isEmpty
        case isNotRunning
        case isNotExist
        case isNull
        case isNotDirectory
        case notSupports
        case noTorch
        case notOpenURL
        case format
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {
            
            switch self {
            case .unknown: return "未知錯誤"
            case .isTooLarge: return "數值過大"
            case .isTooSmall: return "數值過小"
            case .isEmpty: return "資料是空的"
            case .isNotRunning: return "沒有在運作"
            case .isNotExist: return "該資源不存在"
            case .isNull: return "資源是Null"
            case .isNotDirectory: return "不是資料夾"
            case .notSupports: return "該手機不支援"
            case .noTorch: return "該裝置沒有手電筒"
            case .notOpenURL: return "打開URL錯誤"
            case .format: return "設定格式錯誤"
            }
        }
    }
    
    /// [時間的格式](https://nsdateformatter.com)
    enum DateFormat: CustomStringConvertible {
        
        var description: String { return toString() }
        
        case full
        case long
        case meridiem(formatLocale: Locale)
        
        /// [轉成對應的字串](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/dateformatter-的-am-pm-問題-5e0d301e8998)
        private func toString() -> String {
            
            switch self {
            case .full: return "yyyy-MM-dd HH:mm:ss ZZZ"
            case .long: return "yyyy-MM-dd HH:mm:ss"
            case .meridiem: return "yyyy-MM-dd hh:mm a"
            }
        }
    }
    
    /// 產生檔案管理資料夾相關的URL
    enum FileManagerDirectoryType {
        
        case document
        case cache
        case download
        case library
        case temporary
        case searchPathDirectory(_ directory: FileManager.SearchPathDirectory)
        case custom(_ path: String)
        
        /// 取得URL
        /// - Returns: URL?
        func url() -> URL? {
            
            var url: URL?
            
            switch self {
            case .document: url = FileManager.default._userDirectory(for: .documentDirectory).first
            case .cache: url = FileManager.default._userDirectory(for: .cachesDirectory).first
            case .download: url = FileManager.default._userDirectory(for: .downloadsDirectory).first
            case .library: url = FileManager.default._userDirectory(for: .libraryDirectory).first
            case .temporary: url = FileManager.default._temporaryDirectory()
            case .searchPathDirectory(let directory): url = FileManager.default._userDirectory(for: directory).first
            case .custom(let path): url = URL(string: path)
            }
            
            return url
        }
    }
    
    /// [影片的解析度](https://alanhome0814.blogspot.com/2020/07/hdfhdqhduhd.html)
    enum VideoDefinition: Int, CaseIterable, CustomStringConvertible {
        
        var description: String { return message() }
        
        case FHD
        case UHD
        
        /// 由尺寸 => VideoDefinition
        /// - Parameters:
        ///   - size: CGSize
        ///   - orientation: UIImage.Orientation
        /// - Returns: VideoDefinition
        static func parseSize(_ size: CGSize, for orientation: UIImage.Orientation) -> Self {
            if Int(size.width) > FHD.size(for: orientation).width { return .UHD }
            return .FHD
        }
        
        /// 影片的解析度 => 對應Item的方向
        /// - Parameter orientation: 對應圖示的方向 (寬 <=> 高)
        /// - Returns: CGSize
        func size(for orientation: UIImage.Orientation) -> VideoSize {
            
            let size: VideoSize
            
            switch self {
            case .FHD: size = VideoSize(width: 1920, height: 1080)
            case .UHD: size = VideoSize(width: 3840, height: 2160)
            }
            
            switch orientation {
            case .up, .upMirrored, .down, .downMirrored: return VideoSize(width: size.height, height: size.width)
            case .left, .leftMirrored, .right, .rightMirrored: return size
            @unknown default: fatalError()
            }
        }
        
        /// 標題顯示
        /// - Returns: String
        func title() -> String {
            switch self {
            case .FHD: return "FHD"
            case .UHD: return "UHD"
            }
        }
        
        /// 切換設定
        mutating func toggle() {
            self = (self == .FHD) ? .UHD : .FHD
        }
        
        /// 相關訊息
        /// - Returns: String
        private func message() -> String {
            
            switch self {
            case .FHD: return "FHD - Full High Definition"
            case .UHD: return "4K - Ultra High Definition"
            }
        }
    }
}
