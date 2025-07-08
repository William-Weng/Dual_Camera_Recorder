//
//  Models.swift
//  DualCamera
//
//  Created by William.Weng on 2024/10/7.
//

import Foundation
import AVFoundation

final class FileItemModel {
    
    let fileURL: URL
    let asset: AVAsset
    let fileType: UTType
    
    var isSelected: Bool
    
    init(fileURL: URL, asset: AVAsset, fileType: UTType, isSelected: Bool = false) {
        self.fileURL = fileURL
        self.asset = asset
        self.fileType = fileType
        self.isSelected = isSelected
    }
}
