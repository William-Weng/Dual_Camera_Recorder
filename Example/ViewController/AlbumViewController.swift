//
//  AlbumViewController.swift
//  DualCamera
//
//  Created by William.Weng on 2024/10/7.
//

import UIKit
import AVKit
import AVFoundation
import UniformTypeIdentifiers
import WWPrint
import WWCompositionalLayout

// MARK: - AlbumViewControllerDelgate
protocol AlbumViewControllerDelgate: AnyObject {
    
    /// 刪除圖片
    /// - Parameter model: FileItemModel?
    func removeImage(model: FileItemModel?)
}

// MARK: - AlbumViewController
final class AlbumViewController: UIViewController {
    
    @IBOutlet weak var albumCollectionView: UICollectionView!
    @IBOutlet weak var selectedModeButtonItem: UIBarButtonItem!
    
    private let contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
    private let edgeInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
    private let backgroundInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
    
    private var selectedIndexPath: IndexPath?
    private var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearAction()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        previewViewControllerSetting(for: segue, sender: sender)
    }
    
    @IBAction func exchangeSelectedMode(_ sender: UIBarButtonItem) {
        exchangeSelectedModeAction()
    }
    
    deinit {
        AlbumItemCollectionViewCell.reset()
        wwPrint("deinit")
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension AlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AlbumItemCollectionViewCell.fileItemModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return albumCellMaker(with: collectionView, cellForItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItemAction(with: indexPath)
    }
}

// MARK: - AlbumViewControllerDelgate
extension AlbumViewController: AlbumViewControllerDelgate {
    
    func removeImage(model: FileItemModel?) {
        
        guard let selectedIndexPath = selectedIndexPath else { return }
        
        self.selectedIndexPath = nil
        AlbumItemCollectionViewCell.fileItemModels.remove(at: selectedIndexPath.row)
        albumCollectionView.deleteItems(at: [selectedIndexPath])
    }
}

// MARK: - @objc
@objc private extension AlbumViewController {
    
    func handleShareMedia(_ item: UIBarButtonItem) {
        shareMediaAction()
    }
    
    func handleRemoveMedia(_ item: UIBarButtonItem) {
        
        Utility.shared.presentComfireAlertController(target: self, title: Constant.Message.reminder.output(), message: Constant.Message.deleteFile.output(), cancelhandler: nil) {
            self.removeMediaAction()
        }
    }
    
    func handleShardFiles(_ item: UIBarButtonItem) {
        shardFilesAction()
    }
    
    func handleRemoveFiles(_ item: UIBarButtonItem) {
                
        if (AlbumItemCollectionViewCell.selectedItems.isEmpty) { return }
        
        Utility.shared.presentComfireAlertController(target: self, title: Constant.Message.reminder.output(), message: Constant.Message.deleteFiles.output(), cancelhandler: nil) {
            self.removeFilesAction()
        }
    }
}

// MARK: - 主工具
private extension AlbumViewController {
    
    /// 初始化設定
    func initSetting() {
        
        guard let layout = photoAlbumLayout()?._register(with: AlbumItemCollectionViewCell.self, ofKind: .decoration) else { return }
        
        initToolbarItems()
        
        albumCollectionView._delegateAndDataSource(with: self)
        albumCollectionView.setCollectionViewLayout(layout, animated: true)
        
        AlbumItemCollectionViewCell.fileItemModels = Utility.shared.fileItemModels()
    }
    
    /// 初始化Toolbar的功能
    func initToolbarItems() {
        
        let shardFilesItem = UIBarButtonItem(image: UIImage(named: "Share"), style: .plain, target: self, action: #selector(Self.handleShardFiles(_:)))
        let removeFilesItem = UIBarButtonItem(image: UIImage(named: "TrashBin"), style: .plain, target: self, action: #selector(Self.handleRemoveFiles(_:)))
        
        toolbarItems = [shardFilesItem, UIBarButtonItem.flexibleSpace(), removeFilesItem]
    }
    
    /// 畫面將要出現的功能處理
    func viewWillAppearAction() {
        
        playerViewController?.player?.pause()
        playerViewController?.removeFromParent()
        playerViewController = nil
        
        toolbarSetting()
    }
    
    /// 產生相框的Cell
    /// - Parameters:
    ///   - collectionView: UICollectionView
    ///   - indexPath: IndexPath
    /// - Returns: UICollectionViewCell
    func albumCellMaker(with collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView._reusableCell(at: indexPath) as AlbumItemCollectionViewCell
        cell.configure(with: indexPath)
        
        return cell
    }
    
    /// 點選到Item的功能處理
    /// - Parameter indexPath: IndexPath
    func didSelectItemAction(with indexPath: IndexPath) {
        
        if (!AlbumItemCollectionViewCell.isSelectedMode) { previewItemAction(indexPath: indexPath); return }
        selectedItemAction(indexPath: indexPath)
    }
    
    /// Toolbar的顯示設定
    func toolbarSetting() {
        selectedModeButtonItem.image = (!AlbumItemCollectionViewCell.isSelectedMode) ? UIImage(named: "SelectOff") : UIImage(named: "SelectOn")
        navigationController?.isToolbarHidden = (!AlbumItemCollectionViewCell.isSelectedMode)
    }
    
    /// 交換選擇模式的功能處理
    func exchangeSelectedModeAction() {
        
        AlbumItemCollectionViewCell.isSelectedMode.toggle()
        AlbumItemCollectionViewCell.selectedItems.removeAll()
        
        toolbarSetting()
        albumCollectionView.reloadData()
    }
    
    /// 分享檔案 (UIActivityViewController)
    func shardFilesAction() {
        
        if (AlbumItemCollectionViewCell.selectedItems.isEmpty) { return }
        
        let fileURLs = AlbumItemCollectionViewCell.selectedItems.compactMap { AlbumItemCollectionViewCell.fileItemModels[safe: $0.row]?.fileURL }
        let activityViewController = UIActivityViewController._build(activityItems: fileURLs)
        
        present(activityViewController, animated: true) {}
    }
    
    /// 記錄被選到的Item
    /// - Parameter indexPath: IndexPath
    func selectedItemAction(indexPath: IndexPath) {
        
        AlbumItemCollectionViewCell.selectedItems._toggle(indexPath)
        AlbumItemCollectionViewCell.fileItemModels[safe: indexPath.row]?.isSelected = AlbumItemCollectionViewCell.selectedItems.contains(indexPath)
        
        albumCollectionView.visibleCells.forEach { cell in
            
            guard let cell = cell as? AlbumItemCollectionViewCell,
                  cell.indexPath == indexPath
            else {
                return
            }
            
            albumCollectionView.reloadItems(at: [indexPath])
        }
    }
    
    /// 刪除所選到的檔案 (FileManager)
    func removeFilesAction() {
        
        AlbumItemCollectionViewCell.fileItemModels.removeAll { model in
            
            if (!model.isSelected) { return false }
            _ = FileManager.default._removeFile(at: model.fileURL)
            
            return model.isSelected
        }
        
        albumCollectionView.deleteItems(at: Array(AlbumItemCollectionViewCell.selectedItems))
        
        AlbumItemCollectionViewCell.selectedItems.removeAll()
        albumCollectionView.reloadSections(IndexSet(integer: 0))
    }
}

// MARK: - 小工具
private extension AlbumViewController {
    
    /// 照片框的Layout
    /// - Returns: UICollectionViewCompositionalLayout?
    func photoAlbumLayout() -> UICollectionViewCompositionalLayout? {
        
        let layout = WWCompositionalLayout.shared
            .addItem(width: .fractionalWidth(1/3), height: .absolute(120), contentInsets: edgeInsets)
            .setDecoration(with: backgroundInsets)
            .setGroup(width: .fractionalWidth(1.0), height: .absolute(120), scrollingDirection: .horizontal)
            .setSection(with: .none, contentInsets: contentInsets)
            .setHeader(width: .fractionalWidth(1.0), height: .absolute(16))
            .setFooter(width: .fractionalWidth(0.5), height: .absolute(16))
            .build()
        
        return layout
    }
        
    /// 影音圖片預覽功能
    /// - Parameter model: IndexPath
    func previewItemAction(indexPath: IndexPath) {
        
        guard let model = AlbumItemCollectionViewCell.fileItemModels[safe: indexPath.row] else { return }
        selectedIndexPath = indexPath
        
        switch model.fileType {
        case .movie: pushMediaPlayerViewController(videoURL: model.fileURL, shareAction: #selector(handleShareMedia(_:)), removeAction: #selector(handleRemoveMedia(_:)))
        case .audio: pushMediaPlayerViewController(videoURL: model.fileURL, shareAction: #selector(handleShareMedia(_:)), removeAction: #selector(handleRemoveMedia(_:)))
        default: performSegue(withIdentifier: Constant.shared.previewSegue, sender: model)
        }
    }
    
    /// 分享選到的影音檔 (UIActivityViewController)
    func shareMediaAction() {
        
        guard let selectedIndexPath = selectedIndexPath,
              let model = AlbumItemCollectionViewCell.fileItemModels[safe: selectedIndexPath.row],
              let playerViewController = playerViewController
        else {
            return
        }
        
        let activityViewController = UIActivityViewController._build(activityItems: [model.fileURL])
        present(activityViewController, animated: true) { playerViewController.player?.pause() }
    }
    
    /// 移除選到的影音檔 (FileManager)
    func removeMediaAction() {
        
        guard let selectedIndexPath = selectedIndexPath,
              let model = AlbumItemCollectionViewCell.fileItemModels[safe: selectedIndexPath.row]
        else {
            return
        }
        
        let result = FileManager.default._removeFile(at: model.fileURL)
        
        switch result {
        case .failure(let error): Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: error.localizedDescription, handler: nil)
        case .success(let isSuccess):
            
            if (isSuccess) {
                
                self.selectedIndexPath = nil
                AlbumItemCollectionViewCell.fileItemModels.remove(at: selectedIndexPath.row)
                albumCollectionView.deleteItems(at: [selectedIndexPath])
                
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    /// 開始播放影片 / 分享檔案 / 刪除檔案 (AVPlayerViewController)
    /// - Parameters:
    ///   - videoURL: URL
    ///   - shareAction: Selector?
    ///   - removeAction: Selector?
    func pushMediaPlayerViewController(videoURL: URL, shareAction: Selector?, removeAction: Selector?) {
        
        guard let playerViewController = Utility.shared.shareVideoPlayerViewController(target: self, videoURL: videoURL, shareAction: shareAction, removeAction: removeAction) else { return }
        
        self.playerViewController = playerViewController
        
        navigationController?.isToolbarHidden = false
        navigationController?.pushViewController(playerViewController, animated: true)
    }
    
    /// 設定圖片預覽
    /// - Parameters:
    ///   - segue: UIStoryboardSegue
    ///   - sender: Any?
    func previewViewControllerSetting(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? PreviewImageViewController,
              let model = sender as? FileItemModel
        else {
            return
        }
        
        viewController.model = model
        viewController.albumViewControllerDelgate = self
    }
}
