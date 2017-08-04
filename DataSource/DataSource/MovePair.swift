//
//  MovePair.swift
//  DataSource
//
//  Created by Sergiy Loza on 04.08.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import Foundation

class MovePair<T:DataType> {
    
    var object: DataObject<T>
    var from: IndexPath
    var to: IndexPath
    
    init(object: DataObject<T>, from: IndexPath) {
        self.object = object
        self.from = from
        self.to = from
    }
}
