//
//  Center.swift
//  DualCamera
//
//  Created by iOS on 2024/9/27.
//

import UIKit

// MARK: - Center (單例)
final class Center: NSObject {
    private override init() {}
}

// MARK: - 取得裝置資訊
extension Center {
    
    final class UIDeviceManager: NSObject {
        
        static let shared = UIDeviceManager()

        private var resultBlock: ((UIDeviceOrientation) -> (Void))?
        
        private override init() { super.init() }
        
        deinit { NotificationCenter.default.removeObserver(self) }
    }
}

// MARK: - 小工具
extension Center.UIDeviceManager {
    
    /// [取得手機設備旋轉後的方向](https://ithelp.ithome.com.tw/articles/10196923)
    /// - Parameter block: [(UIDeviceOrientation) -> Void)](https://www.hackingwithswift.com/example-code/uikit/how-to-animate-when-your-size-class-changes-willtransitionto)
    func screenOrientation(_ result: @escaping ((UIDeviceOrientation) -> Void)) {
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(Center.UIDeviceManager.orientationAction(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        resultBlock = result
    }
    
    /// [取得手機設備旋轉後的方向](https://ithelp.ithome.com.tw/articles/10196923)
    /// - Returns: [(UIDeviceOrientation) -> Void)](https://www.hackingwithswift.com/example-code/uikit/how-to-animate-when-your-size-class-changes-willtransitionto)
    func screenOrientation() async -> UIDeviceOrientation {
        
        await withCheckedContinuation { continuation in
            self.screenOrientation { result in
                continuation.resume(returning: result)
            }
        }
    }
}

// MARK: - @objc
@objc private extension Center.UIDeviceManager {
    
    /// 回傳手機設備旋轉後的方向
    /// - Parameter notification: Notification
    func orientationAction(_ notification: Notification) {
        resultBlock?(UIDevice.current.orientation)
    }
}
