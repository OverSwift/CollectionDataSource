//
//  ViewController.swift
//  DataSource
//
//  Created by Sergiy Loza on 31.07.17.
//  Copyright © 2017 Lemberg Solutions. All rights reserved.
//

import UIKit

class PhantomObject: NSObject {
    
    var name:String?
}

extension PhantomObject: SectionSupport {
    
    typealias SectionKeyValue = String

    var value: String {
        return name ?? ""
    }
}

class Cell: UICollectionViewCell {
    
    @IBOutlet weak var text: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class ViewController: UIViewController {

    fileprivate var dataSource: DataSource<PhantomObject>!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = DataSource<PhantomObject>(withView: collectionView)
        self.collectionView.delegate = self
        
        dataSource.set { (one, two) -> Bool in
            return one.name ?? "" < two.name ?? ""
        }
        let selector = #selector(handleLongGesture(gesture:))
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: selector)
        self.collectionView.addGestureRecognizer(longPressGesture)
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.global().async {
            self.dataModify()
        }
    }
    
    func dataModify() {
        
        let chars = ["D","B","C","A","E","F","J","K","4","M","N","P","S","O","T","X","Y","Z","1","2","3","L",]
        
        for char in chars {
            let obj = PhantomObject()
            obj.name = char
            dataSource.add(object: obj)
        }
    }
    
    @IBAction func remove(sender: UIButton) {
//        for object in dataSource.items {
//            dataSource.remove(object: object)
//        }
//        dataSource.add(object: PhantomObject())
    }
    
    @IBAction func stopRemove(sender: UIButton) {
//        dataSource.move(from: 1, to: 3, byUser: false)
    }
    
    @IBAction func az(_ sender: UIButton) {
        dataSource.set { (one, two) -> Bool in
            return one.name ?? "" < two.name ?? ""
        }
    }
    
    @IBAction func za(_ sender: UIButton) {
        dataSource.set { (one, two) -> Bool in
            return one.name ?? "" > two.name ?? ""
        }
    }
    
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        
        switch(gesture.state) {
            
        case .began:
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfItems(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Cell
        let obj = dataSource[indexPath]
        cell.text.text = obj.name
        print(obj.name ?? "")
        
        return cell
    }
    
}

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let obj = dataSource[indexPath]
        dataSource.remove(object: obj)
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        dataSource.move(from:sourceIndexPath, to: destinationIndexPath, byUser: true)
    }
}

