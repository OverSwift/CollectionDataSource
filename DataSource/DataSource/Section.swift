//
//  File.swift
//  DataSource
//
//  Created by Sergiy Loza on 14.08.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import Foundation

public typealias SectionKey = (Comparable & Hashable)

public protocol SectionSupport {
    
    associatedtype SectionKeyValue: SectionKey
    var sectionKey:SectionKeyValue { get }
}

    private let syncQueue = DispatchQueue(label: "SectionSynch")

class Section<T:DataType> {
    
    var isNew = true
    var isDitry = false
    var sectionKey: T.SectionKeyValue

    var objects:[DataObject<T>] = []
    {
        didSet {
            
        }
    }
    
    init(key: T.SectionKeyValue) {
        self.sectionKey = key
    }
    
    func add(object: DataObject<T>) {
        syncQueue.sync {
            self.objects.append(object)
        }
    }
    
    func copy() -> Section<T> {
        let copy = Section<T>(key: sectionKey)
        copy.objects = self.objects
        copy.isNew = self.isNew
        copy.isDitry = self.isDitry
        return copy
    }
}

extension Section: CustomStringConvertible {
    
    var description: String {
        var d = ""
        d += "\(objects)"
        return d
    }
}

extension Section: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return description
    }
}

extension Section: Equatable {
    
    static func ==(lhs: Section<T>, rhs: Section<T>) -> Bool {
        return lhs.sectionKey == rhs.sectionKey
    }
}


extension Section: Hashable {
    
    var hashValue: Int {
        return sectionKey.hashValue
    }
}
