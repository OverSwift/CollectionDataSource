//
//  DataObject.swift
//  DataSource
//
//  Created by Sergiy Loza on 15.08.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import Foundation

public typealias DataType = (Hashable & SectionSupport)

protocol Box {
    
    associatedtype ObjectType:DataType
    var value:ObjectType { get }
}

struct DataObject<T:DataType>: Box {
    
    typealias ObjectType = T
    var value: T
}
