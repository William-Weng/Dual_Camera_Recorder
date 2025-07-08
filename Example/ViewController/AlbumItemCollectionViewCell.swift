//
//  AlbumItemTableViewCell.swift
//  DualCamera
//
//  Created by William.Weng on 2024/10/7.
//

import UIKit
import AVFoundation
import WWPrint
import WWCacheManager

// MARK: - AlbumItemCollectionViewCell
final class AlbumItemCollectionViewCell: UICollectionViewCell, CellReusable {
    
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var definitionView: UIView!
    @IBOutlet weak var definitionLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var selectedModeImageView: UIImageView!
    
    static private let cacheManager = WWCacheManager<NSString, UIImage>.build()
    
    static var isSelectedMode = false
    static var fileItemModels: [FileItemModel] = []
    static var selectedItems: Set<IndexPath> = []
    
    var indexPath: IndexPath = []
        
    /// 回復設定值 (清空)
    static func reset() {
        isSelectedMode = false
        fileItemModels = []
        selectedItems = []
    }
    
    /// 畫面設定
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath) {
        
        guard let model = Self.fileItemModels[safe: indexPath.row] else { return }
        
        self.indexPath = indexPath
        selectedModeImageView.layer.cornerRadius = selectedModeImageView.frame.width * 0.5
        initSetting(with: model)
    }
        
    deinit {
        wwPrint("deinit")
    }
}

// MARK: - 主工具
private extension AlbumItemCollectionViewCell {
    
    /// 初始化設定
    /// - Parameter model: FileItemModel
    func initSetting(with model: FileItemModel) {
        
        selectedModeSetting()
        thumbnailSetting(model: model)
        
        switch model.fileType {
        case .movie: videoSetting(model: model)
        case .jpeg: imageSetting(model: model)
        case .audio: audioSetting(model: model)
        default: break
        }
    }
    
    /// 取得完整檔案的URL
    /// - Parameter filename: String
    /// - Returns: URL?
    func fileUrl(with filename: String) -> URL? {
        
        guard let folderUrl = Utility.shared.folderUrl() else { return nil }
        
        let fullFileUrl = folderUrl.appendingPathComponent(filename, isDirectory: false)
        return fullFileUrl
    }
}

// MARK: - 小工具
private extension AlbumItemCollectionViewCell {
        
    /// 針對影片的畫面設定
    /// - Parameter model: FileItemModel
    func videoSetting(model: FileItemModel) {
        
        Task {
            let seconds = try await model.asset._seconds().get() ?? 0
            let size = try await model.asset._videoTrack()?._size().get() ?? .zero
            
            timeLabel.text = seconds._time()
            definitionLabel.text = Constant.VideoDefinition.parseSize(size, for: .up).title()
        }
    }
    
    /// 針對圖片的畫面設定
    /// - Parameter model: FileItemModel
    func imageSetting(model: FileItemModel) {}
    
    /// 針對聲音的畫面設定
    /// - Parameter model: FileItemModel
    func audioSetting(model: FileItemModel) {
        
        Task {
            let seconds = try await model.asset._seconds().get() ?? 0
            timeLabel.text = seconds._time()
        }
    }
    
    /// 縮圖顯示設定 <=> 快取圖片
    /// - Parameter model: FileItemModel
    func thumbnailSetting(model: FileItemModel) {
        
        var thumbnail: UIImage?
        
        defer {
            let isHidden = (model.fileType == .jpeg)
            viewSetting(isHidden: isHidden, image: thumbnail, contentMode: .scaleAspectFill)
        }
        
        if let cacheImage = Self.cacheManager.value(forKey: model.fileURL.lastPathComponent as NSString) { thumbnail = cacheImage; return }
        
        if let _thumbnail = Utility.shared.albumItemImage(model: model) {
            thumbnail = _thumbnail
            if (model.fileType != .audio) { Self.cacheManager.setValue(_thumbnail, forKey: model.fileURL.lastPathComponent as NSString) }
        }
    }
    
    /// 畫面相關設定
    /// - Parameters:
    ///   - isHidden: Bool
    ///   - image: UIImage?
    ///   - contentMode: UIView.ContentMode
    func viewSetting(isHidden: Bool, image: UIImage?, contentMode: UIView.ContentMode) {
        
        timeView.isHidden = isHidden
        definitionView.isHidden = isHidden
        thumbnailImageView.image = image
        thumbnailImageView.contentMode = contentMode
    }
    
    /// 是不是選取模式的相關設定
    func selectedModeSetting() {
        
        selectedModeImageView.isHidden = !Self.isSelectedMode
        selectedModeImageView.backgroundColor = .clear
        
        if (Self.selectedItems.contains(indexPath)) { selectedModeImageView.backgroundColor = .systemPink }
    }
}
