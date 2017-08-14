//
//  DataSource.swift
//  DataSource
//
//  Created by Sergiy Loza on 31.07.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import UIKit

public typealias SectionKey = (Comparable & Hashable)

public protocol SectionSupport {
    
    associatedtype SectionKeyValue: SectionKey
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
    var isDitry = false
    var sectionKey: T.SectionKeyValue
    fileprivate var objects:[DataObject<T>] = []
    
    init(key: T.SectionKeyValue) {
        self.sectionKey = key
    }
}

extension Section : Equatable {
    
    static func ==(lhs: Section<T>, rhs: Section<T>) -> Bool {
        return lhs.sectionKey == rhs.sectionKey
    }
}


extension Section: Hashable {
    
    var hashValue: Int {
        return sectionKey.hashValue
    }
}


public class DataSource<T:DataType> {

    private var updateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "data.adapter.queue"
        return queue
    }()
    
    private(set) var sections:[Section<T>] = [] {
        didSet {
            if Thread.current == Thread.main {
                fatalError("sections modified from main thread")
            }
        }
    }

    public var items:[T] {
        return sections.reduce([T]()) { (current, section) -> [T] in
            return section.objects.map({ (dataObj) -> T in
                return dataObj.value
            })
        }
    }
    
    public var numberOfSections: Int {
        return sections.count
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
            print("Create new section for \(object)")
            let newSection = Section<T>(key: object.value)
            sections.append(newSection)
            sections.sort(by: { (lhs, rhs) -> Bool in
                return lhs.sectionKey > rhs.sectionKey
            })
            return newSection
        }
        
        print("Section for object \(object) found")
        
        return section
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
    
    public subscript(path: IndexPath) -> T {
        return sections[path.section].objects[path.row].value
    }
    
    func updateSort() {

        let operation = UpdateOperation()
        var pairs = Array<MovePair<T>>()

        operation.arrayModify = {
            
            let old = Array(self.sections)
            
            for (i, s) in old.enumerated() {
                for (j, o) in s.objects.enumerated() {
                    let path = IndexPath(item: j, section: i)
                    let pair = MovePair(object: o, from: path)
                    pairs.append(pair)
                }
            }
            
            self.sortSections()
            
            for (i, s) in self.sections.enumerated() {
                for (j, o) in s.objects.enumerated() {
                    let optPair = pairs.first(where: { (pair) -> Bool in
                        return pair.object.value == o.value
                    })
                    
                    guard let pair = optPair else {
                        fatalError("Pair not found for object \(o)")
                    }
                    pair.to = IndexPath(item: j, section: i)
                }
            }
            
            return true
        }

        operation.applyChanges = {
            
            self.view?.update(with: { 
                for pair in pairs {
                    self.view?.moveItem(from: pair.from, to: pair.to)
                }
            }, completion: { (_) in
                operation.end()
            })
        }
        
        updateQueue.addOperation(operation)
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
            
            var filteredObjects = [T]()
            
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
            
            self.sortSections()
            
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
                    print("Insert section at index \(sectionIndex)")
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
    
    private func sortSections() {
        self.sections.forEach({ (section) in
            if section.isNew || section.isDitry {
                section.objects.sort(by: { (lhs, rhs) -> Bool in
                    return self.sort?(lhs.value, rhs.value) ?? false
                })
                section.isDitry = false
            }
        })
    }
    
    public func remove(objects: [T]) {

        if objects.isEmpty { return }
        
        let operation = UpdateOperation()
        
        var removeSections = IndexSet()
        var removePath = [IndexPath]()
        
        operation.arrayModify = {
            print("Modify remove called")
            
            var sections = [Section<T>]()
            
            for (i, section) in self.sections.enumerated() {
                
                let newSection = Section<T>(key: section.sectionKey)
                newSection.isNew = false
                
                for (j, object) in section.objects.enumerated() {
                    if objects.contains(object.value) {
                        let path = IndexPath(item: j, section: i)
                        removePath.append(path)
                    } else {
                        newSection.objects.append(object)
                    }
                }
                
                if newSection.objects.isEmpty {
                    removeSections.insert(i)
                } else {
                    sections.append(newSection)
                }
            }
            
            self.sections = sections
            self.sortSections()
            
            removePath = removePath.filter({ (path) -> Bool in
                return !removeSections.contains(path.section)
            })
            
            return true
        }

        operation.applyChanges = {
            self.view?.update(with: {
                for sectionIndex in removeSections {
                    self.view?.removeSection(at: sectionIndex)
                }
                for path in removePath {
                    self.view?.removeItem(at: path)
                }
            }, completion: { (finished) in
                operation.end()
            })
        }
        
        updateQueue.addOperation(operation)
    }
    
    private func contains(object: T) -> Bool {
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
    
    public func move(from : IndexPath, to: IndexPath, byUser: Bool) {
        let operation = UpdateOperation()
        
        operation.arrayModify = {
            let object = self.sections[from.section].objects.remove(at: from.row)
            self.sections[to.section].objects.insert(object, at: to.row)
            return !byUser
        }
        
        operation.applyChanges = {
            self.view?.update(with: {
                self.view?.moveItem(from: from, to: to)
            }, completion: { (_) in
                operation.end()
            })
        }
        
        updateQueue.addOperation(operation)
    }
    
    public func stop() {
        updateQueue.cancelAllOperations()
    }
}
