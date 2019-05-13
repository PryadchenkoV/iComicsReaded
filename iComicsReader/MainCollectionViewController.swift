//
//  MainCollectionViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 10/04/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit
import CoreData

class MainCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let comiscCellId = "ComiscView"
    let comiscArray = [NSManagedObject]()

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: comiscCellId, for: indexPath) as? ComiscCollectionViewCell else {
            fatalError("Cell Not Created")
        }
        cell.frame.size = CGSize(width: collectionView.frame.width / 2 - 20, height: collectionView.frame.width / 2 - 20) 
        return cell
    }

}
