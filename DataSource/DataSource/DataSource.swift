//
//  DataSource.swift
//  DataSource
//
//  Created by Sergiy Loza on 31.07.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import UIKit

public protocol SectionSupport {
    
    associatedtype SectionKeyValue: Comparable
    var value:SectionKeyValue { get }
}

public typealias DataType = (Hashable & SectionSupport)

protocol Box {
    
    associatedtype ObjectType:DataType
    var value:ObjectType { get }
}

struct DataObject<T:DataType>: Box {
    
    typealias ObjectType = T
    var value: T
}

class Section<T:DataType> {
    
    var isNew = true
    var isDitry = true
    var sectionKey: T.SectionKeyValue
    fileprivate var objects:[DataObject<T>] = []
    
    init(key: T.SectionKeyValue) {
        self.sectionKey = key
    }
}

public class DataSource<T:DataType> {

    private var updateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "data.adapter.queue"
        return queue
    }()
    
//    private var objects:[DataObject<T>] = []
    
    private var sections:[Section<T>] = []

    public var items:[T] {
        return sections.reduce([T]()) { (current, section) -> [T] in
            return section.objects.map({ (dataObj) -> T in
                return dataObj.value
            })
        }
    }
    
    public func numberOfItems(in section:Int) -> Int {
        return sections[section].objects.count
    }
    
    func section(for object:T) -> Section<T> {
        
        var objectSection: Section<T>? = nil
        
        for section in self.sections {
            if object.value == section.sectionKey {
                objectSection = section
            }
        }
        
        guard let section = objectSection else {
            let newSection = Section<T>(key: object.value)
            sections.append(newSection)
            sections.sort(by: { (lhs, rhs) -> Bool in
                return lhs.sectionKey > rhs.sectionKey
            })
            print("Print \(sections)")
            return newSection
        }
        return section
    }
    
    public var numberOfSections: Int {
        return sections.count
    }
    
    open private(set) weak var view:AnimatableCollection?
    
    public typealias SortType = (T,T) -> Bool
    
    public var sort:SortType?{
        didSet {
            updateSort()
        }
    }
    
    public init(withView view:AnimatableCollection) {
        self.view = view
    }
    
    func updateSort() {

//        let operation = UpdateOperation()
//        var pairs = Array<MovePair<T>>()
//
//        operation.arrayModify = {
//            
//            let old = Array(self.objects)
//            
//            for (i, obj) in old.enumerated() {
//                let path = IndexPath(item: i, section: 0)
//                let pair = MovePair(object: obj, from: path)
//                pairs.append(pair)
//            }
//            
//            self.objects.sort(by: { (lhs, rhs) -> Bool in
//                return self.sort?(lhs.value, rhs.value) ?? false
//            })
//            
//            for pair in pairs {
//                let index = self.objects.index(where: { (obj) -> Bool in
//                    return obj.value == pair.object.value
//                })
//                guard let i = index else {
//                    continue
//                }
//                let path = IndexPath(item: i, section: 0)
//                pair.to = path
//            }
//            
//            return true
//        }
//        
//        operation.applyChanges = {
//            
//            self.view?.update(with: { 
//                for pair in pairs {
//                    self.view?.moveItem(from: pair.from, to: pair.to)
//                }
//            }, completion: { (_) in
//                operation.end()
//            })
//        }
//        
//        updateQueue.addOperation(operation)
    }
    
    public func set(sort:SortType?) {
        self.sort = sort
    }
    
    public func add(object: T) {
        add(objects: [object])
    }
    
    public func add(objects: [T]) {
        
        if objects.isEmpty { return }

        let operation = UpdateOperation()
        
        var newSection = IndexSet()
        var newPaths = [IndexPath]()
        
        operation.arrayModify = {
            
            var filteredObjects = Array<T>()
            
            for object in objects {
                if !self.contains(object: object) {
                    filteredObjects.append(object)
                }
            }
            
            if filteredObjects.isEmpty {
                return false
            }
            
            for object in filteredObjects {
                let wraper = DataObject(value: object)
                let section = self.section(for: object)
                section.objects.append(wraper)
                section.isDitry = true
            }
            
            self.sections.forEach({ (section) in
                if section.isNew || section.isDitry {
                    section.objects.sort(by: { (lhs, rhs) -> Bool in
                        return self.sort?(lhs.value, rhs.value) ?? false
                    })
                }
            })
            
            
            for (i, section) in zip(self.sections.indices, self.sections) {
                
                if section.isNew {
                    print("Add index \(i)")
                    newSection.insert(i)
                    section.isNew = false
                    continue
                }
                
                for object in filteredObjects {
                    let index = section.objects.index { (obj) -> Bool in
                        return obj.value == object
                    }
                    guard let a = index else {
                        continue
                    }
                    let path = IndexPath(item: a, section: i)
                    newPaths.append(path)
                }
            }
            return true
        }
        
        operation.applyChanges = {
            self.view?.update(with: {
                
                for sectionIndex in newSection {
                    self.view?.insertSection(at: sectionIndex)
                }
                
                for path in newPaths {
                    self.view?.insertItem(at: path)
                }
                
            }, completion: { (finished) in
                operation.end()
            })
        }
        
        updateQueue.addOperation(operation)
    }
    
    public func remove(object: T) {
        remove(objects: [object])
    }
    
    public func remove(objects: [T]) {

//        if objects.isEmpty { return }
//        
//        let operation = UpdateOperation()
//        
//        var indexes = IndexSet()
//
//        operation.arrayModify = {
//            print("Modify remove called")
//            
//            for object in objects {
//                let index = self.objects.index { (obj) -> Bool in
//                    return obj.value == object
//                }
//                guard let a = index else {
//                    return false
//                }
//                indexes.insert(a)
//            }
//            
//            for object in objects {
//                let index = self.objects.index { (obj) -> Bool in
//                    return obj.value == object
//                }
//                guard let i = index else {
//                    return false
//                }
//                self.objects.remove(at: i)
//            }
//            
//            return true
//        }
//        
//        operation.applyChanges = {
//            self.view?.update(with: {
//                for i in indexes {
//                    let path = IndexPath(item: i, section: 0)
//                    self.view?.removeItem(at: path)
//                }
//            }, completion: { (finished) in
//                operation.end()
//            })
//        }
//        
//        updateQueue.addOperation(operation)
    }
    
    func contains(object: T) -> Bool {
        var old:T?
        for s in sections {
            let a = s.objects.first { (obj) -> Bool in
                return obj.value == object
            }
            if let aa = a {
                old = aa.value
                break
            }
        }
        return old != nil
    }
    
    public func move(from :Int, to: Int, byUser:Bool) {
        
//        let operation = UpdateOperation()
//        
//        operation.arrayModify = {
//            let obj = self.objects.remove(at: from)
//            self.objects.insert(obj, at: to)
//            return !byUser
//        }
//        
//        operation.applyChanges = {
//            self.view?.update(with: {
//                let fromPath = IndexPath(item: from, section: 0)
//                let toPath = IndexPath(item: to, section: 0)
//                self.view?.moveItem(from: fromPath, to: toPath)
//            }, completion: { (_) in
//                operation.end()
//            })
//        }
        
//        updateQueue.addOperation(operation)
    }
    
    public func stop() {
        updateQueue.cancelAllOperations()
    }
}
