//
//  DataSource.swift
//  DataSource
//
//  Created by Sergiy Loza on 31.07.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import UIKit

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
    
    public var numberOfSections: Int = 0
    
    public func numberOfItems(in section:Int) -> Int {
        return sections[section].objects.count
    }
    
    func section(for object:T) -> Section<T> {
        
        var objectSection: Section<T>? = nil
        
        for section in self.sections {
            if object.sectionKey == section.sectionKey {
                objectSection = section
            }
        }
        
        guard let section = objectSection else {
            let newSection = Section<T>(key: object.sectionKey)
            sections.append(newSection)
            sections.sort(by: { (lhs, rhs) -> Bool in
                return lhs.sectionKey > rhs.sectionKey
            })
            return newSection
        }
        
        return section
    }
    
    open private(set) weak var view:AnimatableCollection?
    
    public typealias SortType = (T,T) -> Bool
    
    public var sort:SortType?{
        didSet {
            updateSort()
        }
    }
    
    public init(with view:AnimatableCollection) {
        self.view = view
    }
    
    public subscript(path: IndexPath) -> T? {

        if path.section < sections.count {
            let s = sections[path.section]
            if path.row < s.objects.count {
                print("⚠️ Found ⚠️")
                return s.objects[path.row].value
            }
        }
        print("❌ ups ❌")
        return nil
    }
    
    func updateSort() {

        let operation = UpdateOperation()
        var pairs = [MovePair<T>]()
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

        operation.applyChanges = { [weak self] (completion)  in
            self?.view?.update(with: {
                for pair in pairs {
                    self?.view?.moveItem(from: pair.from, to: pair.to)
                }
            }, completion: { (_) in
                completion()
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
        
            var filteredSet = Set<T>()
            
            for object in objects {
                filteredSet.insert(object)
            }
            
            if filteredSet.isEmpty {
                return false
            }
            
            for object in filteredSet {
                let wraper = DataObject(value: object)
                let section = self.section(for: object)
                section.add(object: wraper)
                section.isDitry = true
            }
            
            self.sortSections()
            
            for (sectionIndex, section) in self.sections.enumerated() {
                
                if section.isNew {
                    print("Add index \(sectionIndex)")
                    newSection.insert(sectionIndex)
                    section.isNew = false
                    continue
                }
                
                for (objIndex, obj) in section.objects.enumerated() {
                    
                    if !obj.isNew { // just skip old objects
                        continue
                    }
                    if filteredSet.contains(obj.value) {
                        let path = IndexPath(item: objIndex, section: sectionIndex)
                        newPaths.append(path)
                    }
                    obj.isNew = false
                }
            }
            return true
        }
        
        operation.applyChanges = { [weak self] (completion)  in
            self?.view?.update(with: {
                
                for sectionIndex in newSection {
                    print("Insert section at index \(sectionIndex)")
                    self?.view?.insertSection(at: sectionIndex)
                }
                
                for path in newPaths {
                    self?.view?.insertItem(at: path)
                }
                
                self?.numberOfSections = self?.sections.count ?? 0
            }, completion: { (finished) in
                print("\(String(describing: self?.updateQueue.operationCount))")
                
                completion()
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
            
            for (sectionindex, section) in self.sections.enumerated() {
                
                let newSection = Section<T>(key: section.sectionKey)
                newSection.isNew = false
                
                for (objectIndex, object) in section.objects.enumerated() {
                    if objects.contains(object.value) {
                        let path = IndexPath(item: objectIndex, section: sectionindex)
                        removePath.append(path)
                    } else {
                        newSection.objects.append(object)
                    }
                }
                
                if newSection.objects.isEmpty {
                    removeSections.insert(sectionindex)
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
        
        operation.applyChanges = { [weak self] (completion) in
            self?.view?.update(with: {
                for sectionIndex in removeSections {
                    self?.view?.removeSection(at: sectionIndex)
                }
                for path in removePath {
                    self?.view?.removeItem(at: path)
                }
                self?.numberOfSections = self?.sections.count ?? 0
            }, completion: { (finished) in
                completion()
            })
        }
        
        updateQueue.addOperation(operation)
    }
    
    private func contains(object: T) -> Bool {
        
        for section in sections {
            for obj in section.objects {
                if object == obj.value {
                    return true
                }
            }
        }
        return false
    }
    
    public func move(from : IndexPath, to: IndexPath, byUser: Bool) {
        let operation = UpdateOperation()
        
        operation.arrayModify = {
            let object = self.sections[from.section].objects.remove(at: from.row)
            self.sections[to.section].objects.insert(object, at: to.row)
            return !byUser
        }
        
        operation.applyChanges = { [weak self] (completion) in
            self?.view?.update(with: {
                self?.view?.moveItem(from: from, to: to)
            }, completion: { (_) in
                completion()
            })
        }
        
        updateQueue.addOperation(operation)
    }
    
    public func stop() {
        updateQueue.cancelAllOperations()
    }
}
