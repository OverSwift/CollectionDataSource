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

class DataObject<T:DataType>: Box {
    
    typealias ObjectType = T
    var value: T
    var isNew = true
    
    init(value: T) {
        self.value = value
    }
    
    static func ==(lhs: DataObject<T>, rhs: DataObject<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

extension DataObject: Equatable {
    
}


extension DataObject: CustomStringConvertible {
    
    var description: String {
        return "\(value)"
    }
}

extension DataObject: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return description
    }
}
