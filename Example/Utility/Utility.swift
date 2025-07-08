//
//  Utility.swift
//  DualCamera
//
//  Created by William.Weng on 2024/10/7.
//

import UIKit
import AVFoundation
import AVKit

// MARK: - 常用小工具
final class Utility: NSObject {
    
    static let shared = Utility()
    
    private override init() {}
}

// MARK: - 主工具
extension Utility {
    
    /// 要存影片檔的URL
    /// - Returns: URL?
    func videoUrl() -> URL? {
        return fileURL(for: Constant.shared.folderType, fileType: Constant.shared.fileType.video)
    }
    
    /// 要存圖片檔的URL
    /// - Returns: URL?
    func imageUrl() -> URL? {
        return fileURL(for: Constant.shared.folderType, fileType: Constant.shared.fileType.image)
    }
    
    /// 要存錄音檔的URL
    /// - Returns: URL?
    func audioUrl() -> URL? {
        return fileURL(for: Constant.shared.folderType, fileType: Constant.shared.fileType.audio)
    }
    
    /// 要存影片的資料夾URL
    /// - Returns: URL?
    func folderUrl() -> URL? {
        return FileManager.default._directoryURL(for: Constant.shared.folderType)
    }
    
    /// 分享檔案 / 刪除檔案 (AVPlayerViewController)
    /// - Parameters:
    ///   - target: Any?
    ///   - videoURL: URL
    ///   - shareAction: Selector?
    ///   - removeAction: Selector?
    func shareVideoPlayerViewController(target: Any?, videoURL: URL, shareAction: Selector?, removeAction: Selector?) -> AVPlayerViewController? {
        
        let playerViewController = AVPlayerViewController._build(videoURL: videoURL, on: nil)
        let shardFilesItem = UIBarButtonItem(image: UIImage(named: "Share"), style: .plain, target: target, action: shareAction)
        let removeFilesItem = UIBarButtonItem(image: UIImage(named: "TrashBin"), style: .plain, target: target, action: removeAction)
        
        playerViewController.toolbarItems = [shardFilesItem, UIBarButtonItem.flexibleSpace(), removeFilesItem]
        playerViewController.player?.play()
        
        return playerViewController
    }
    
    /// 彈出訊息提示AlertController
    /// - Parameters:
    ///   - target: UIViewController
    ///   - title: String?
    ///   - message: String?
    ///   - handler: (() -> Void)?
    func presentAlertController(target: UIViewController, title: String?, message: String?, handler: (() -> Void)?) {
        
        let actions: [Constant.AlertActionInformation] = [(title: "OK", style: .default, handler: handler)]
        let alertController = UIAlertController._build(with: title, message: message, actions: actions)
        
        target.present(alertController, animated: true)
    }
    
    /// 彈出確認提示AlertController
    /// - Parameters:
    ///   - target: UIViewController
    ///   - title: String?
    ///   - message: String?
    ///   - cancelhandler: (() -> Void)?
    ///   - surehandler: (() -> Void)?
    func presentComfireAlertController(target: UIViewController, title: String?, message: String?, cancelhandler: (() -> Void)?, surehandler: (() -> Void)?) {
        
        let actions: [Constant.AlertActionInformation] = [
            (title: "NO", style: .cancel, handler: cancelhandler),
            (title: "YES", style: .destructive, handler: surehandler),
        ]
        
        let alertController = UIAlertController._build(with: title, message: message, actions: actions)

        target.present(alertController, animated: true)
    }
    
    /// 讀取資料夾 => 取得影片 / 圖片 / 聲音的資訊
    /// - Returns: [VideoItemModel]
    func fileItemModels() -> [FileItemModel] {
        
        guard let folderUrl = folderUrl(),
              let filenameList = try? FileManager.default._fileList(with: folderUrl).get()
        else {
            return []
        }
        
        let models = filenameList.sorted().map { filename in
            
            let fileURL = folderUrl.appendingPathComponent(filename, isDirectory: false)
            let asset = AVAsset._build(url: fileURL)
            let fileType = try? fileURL._checkType(conforms: [.movie, .jpeg, .audio]).get()
            let model = FileItemModel(fileURL: fileURL, asset: asset, fileType: fileType ?? .data)
            
            return model
        }
        
        return models
    }
    
    /// 取得檔案的顯示縮圖
    /// - Parameters:
    ///   - model: FileItemModel
    ///   - maximumSize: CGSize
    /// - Returns: UIImage?
    func albumItemImage(model: FileItemModel, maximumSize: CGSize = .init(width: 256, height: 256)) -> UIImage? {
        
        switch model.fileType {
        case .movie:
            guard let cgImage = try? AVAssetImageGenerator._screenshot(url: model.fileURL, maximumSize: maximumSize).get() else { return nil }
            return UIImage(cgImage: cgImage)
            
        case .jpeg:
            let image = UIImage(contentsOfFile: model.fileURL.path)
            return image?._thumbnail(of: maximumSize)
            
        case .audio: return Constant.shared.audioImage
        default: return nil
        }
    }
    
    /// 取得相簿的最後一個檔案的縮圖
    /// - Returns: UIImage?
    func lastAlbumItemThumbnail() -> UIImage? {
        guard let model = fileItemModels().last else { return nil }
        return albumItemImage(model: model)
    }
}

// MARK: - 小工具
private extension Utility {
    
    /// 取得檔案完整路徑
    /// - Parameters:
    ///   - folderType: Constant.FileManagerDirectoryType
    ///   - fileType: AVFileType
    /// - Returns: URL?
    func fileURL(for folderType: Constant.FileManagerDirectoryType, fileType: AVFileType) -> URL? {
        
        guard let directoryURL = FileManager.default._directoryURL(for: folderType) else { return nil }
        
        let date = Date()._localTime(timeZone: .current)
        let filename = date ?? Date().timeIntervalSince1970.description
        let fileURL = directoryURL.appendingPathComponent("\(filename)\(fileType._extension())")
        
        return fileURL
    }
}
