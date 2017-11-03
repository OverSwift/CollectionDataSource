//
//  UpdateOperation.swift
//  DataSource
//
//  Created by Sergiy Loza on 01.08.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import Foundation

class UpdateOperation: Operation {
    
    class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["updating" as NSObject]
    }
    
    private var updating = true {
        willSet {
            self.willChangeValue(forKey: "isFinished")
        } didSet {
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    var arrayModify:(() -> Bool)?
    var applyChanges: ((_ completionHandler: @escaping () -> ()) -> ())?
    
    override func cancel() {
        super.cancel()
        updating = false
    }
    
    override var isFinished: Bool {
        if updating {
            return false
        } else {
            return true
        }
    }
    
    override var isExecuting: Bool {
        if updating {
            return true
        } else {
            return false
        }
    }
    
    override func start() {
        if isCancelled {
            return
        }
        super.start()
    }
    
    override func main() {
        super.main()
        
        if isCancelled {
            updating = false
            return
        }
        
        print("START OPERATION")
        
        if arrayModify?() ?? false {
            OperationQueue.main.addOperation { [weak self] in
                self?.applyChanges? { [weak self] in
                    self?.end()
                }
            }
        } else {
            end()
        }
    }
    
    private func end() {
        updating = false
        print("END OPERATION")
    }
    
    override var isAsynchronous: Bool {
        return false
    }
    
    override var isConcurrent: Bool {
        return false
    }
}
