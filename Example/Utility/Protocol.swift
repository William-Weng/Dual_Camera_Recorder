//
//  Protocol.swift
//  Example
//
//  Created by William.Weng on 2024/9/24.
//

import UIKit

// MARK: - 擴充用
protocol Subtractable {
    
    /// 減法 (擴充Int / Double)
    /// - Parameters:
    ///   - lhs: Self
    ///   - rhs: Self
    /// - Returns: Self
    static func -(lhs: Self, rhs: Self) -> Self
}

// MARK: - 可重複使用的Cell (UITableViewCell / UICollectionViewCell)
protocol CellReusable: AnyObject {
    
    static var identifier: String { get }           /// Cell的Identifier
    var indexPath: IndexPath { get }                /// Cell的IndexPath
    
    /// Cell的相關設定
    /// - Parameter indexPath: IndexPath
    func configure(with indexPath: IndexPath)
}

// MARK: - 預設 identifier = class name (初值)
extension CellReusable {
    static var identifier: String { return String(describing: Self.self) }
    var indexPath: IndexPath { return [] }
}
