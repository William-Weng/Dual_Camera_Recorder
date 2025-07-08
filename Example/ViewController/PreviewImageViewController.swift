//
//  PreviewImageViewController.swift
//  DualCamera
//
//  Created by William.Weng on 2024/10/9.
//

import UIKit
import WWPrint

// MARK: - PreviewImageViewController
final class PreviewImageViewController: UIViewController {
    
    @IBOutlet weak var previewImageView: UIImageView!

    weak var albumViewControllerDelgate: AlbumViewControllerDelgate?
    
    var model: FileItemModel?
    
    private var imageCenter: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting(model: model)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imageCenter = previewImageView.center
    }
        
    deinit {
        albumViewControllerDelgate = nil
        wwPrint("deinit")
    }
}

// MARK: - @objc
@objc private extension PreviewImageViewController {
    
    func handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
        resetImageView()
    }
    
    func handleShareImage(_ sender: UIBarButtonItem) {
        shareImageAction()
    }
    
    func handleRemoveImage(_ sender: UIBarButtonItem) {
        
        Utility.shared.presentComfireAlertController(target: self, title: Constant.Message.reminder.output(), message: Constant.Message.deleteImage.output(), cancelhandler: nil) {
            self.removeImageAction()
        }
    }
}

// MARK: - 主工具
private extension PreviewImageViewController {
    
    /// 初始化設定
    /// - Parameter model: FileItemModel?
    func initSetting(model: FileItemModel?) {
        
        guard let model = model else { return }
        
        previewImageView.image = UIImage(contentsOfFile: model.fileURL.path)
        previewImageView._gestureRecognizerSetting(types: [.drag, .scale])
        
        initTapSetting()
        initToolbarItems()
    }
    
    /// 初始化雙點擊的設定
    func initTapSetting() {
        
        let tapGesture = UITapGestureRecognizer._build(target: self, numberOfTapsRequired: 2, action: #selector(Self.handleDoubleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    /// 初始化Toolbar的功能
    func initToolbarItems() {
        
        let shardFilesItem = UIBarButtonItem(image: UIImage(named: "Share"), style: .plain, target: self, action: #selector(Self.handleShareImage(_:)))
        let removeFilesItem = UIBarButtonItem(image: UIImage(named: "TrashBin"), style: .plain, target: self, action: #selector(Self.handleRemoveImage(_:)))
        
        navigationController?.isToolbarHidden = false
        toolbarItems = [shardFilesItem, UIBarButtonItem.flexibleSpace(), removeFilesItem]
    }
    
    /// 分享圖片
    func shareImageAction() {
        
        guard let imageUrl = model?.fileURL else { return }
        
        let activityViewController = UIActivityViewController._build(activityItems: [imageUrl])
        present(activityViewController, animated: true)
    }
    
    /// 刪除圖片
    func removeImageAction() {
        
        guard let imageUrl = model?.fileURL else { return }
        
        switch FileManager.default._removeFile(at: imageUrl) {
        case .failure(let error): Utility.shared.presentAlertController(target: self, title: Constant.Message.error.output(), message: error.localizedDescription, handler: nil)
        case .success(let isSuccess):
            
            if (isSuccess) {
                navigationController?.popViewController(animated: true)
                albumViewControllerDelgate?.removeImage(model: model)
            }
        }
    }
    
    /// 回復ImageView的原始位置 / 大小
    func resetImageView() {
        previewImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        previewImageView.center = imageCenter ?? view.center
    }
}
