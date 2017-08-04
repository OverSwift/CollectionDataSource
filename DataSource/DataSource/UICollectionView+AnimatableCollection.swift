//
//  UICollectionView+AnimatableCollection.swift
//  DataSource
//
//  Created by Sergiy Loza on 01.08.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import UIKit

extension UICollectionView: AnimatableCollection {
    
    func insertItem(at path: IndexPath) {
        insertItems(at: [path])
    }
    
    func removeItem(at path: IndexPath) {
        deleteItems(at: [path])
    }
    
    func moveItem(from path: IndexPath, to newPath: IndexPath) {
        moveItem(at: path, to: newPath)
    }
    
    func update(with animations: @escaping () -> (), completion: @escaping (Bool) -> ()) {
        self.performBatchUpdates(animations, completion: completion)
    }
}
