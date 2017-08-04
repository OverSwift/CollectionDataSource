//
//  AnimatableCollection.swift
//  DataSource
//
//  Created by Sergiy Loza on 01.08.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import Foundation

protocol AnimatableCollection: class {
    
    func update(with animations: @escaping () -> (), completion: @escaping (Bool) -> ())
    func insertItem(at path: IndexPath)
    func removeItem(at path: IndexPath)
    func moveItem(from path: IndexPath, to newPath: IndexPath)
}
