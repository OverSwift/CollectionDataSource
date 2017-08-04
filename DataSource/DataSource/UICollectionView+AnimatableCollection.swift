//
//  UICollectionView+AnimatableCollection.swift
//  DataSource
//
//  Created by Sergiy Loza on 01.08.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import UIKit

extension UICollectionView: AnimatableCollection {
    
    public func insertItem(at path: IndexPath) {
        insertItems(at: [path])
    }
    
    public func removeItem(at path: IndexPath) {
        deleteItems(at: [path])
    }
    
    public func moveItem(from path: IndexPath, to newPath: IndexPath) {
        moveItem(at: path, to: newPath)
    }
    
    public func update(with animations: @escaping () -> (), completion: @escaping (Bool) -> ()) {
        self.performBatchUpdates(animations, completion: completion)
    }
}
