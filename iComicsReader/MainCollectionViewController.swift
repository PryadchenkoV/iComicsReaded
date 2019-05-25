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
        return ComicsGetter.shared.arrayOfComics.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: comiscCellId, for: indexPath) as? ComiscCollectionViewCell else {
            fatalError("Cell Not Created")
        }
        return cell
    }

}

extension MainCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat =  19
        let cellWidth = (UIApplication.shared.delegate as! AppDelegate).screenWidth / 2 - padding
        return CGSize(width: cellWidth, height: cellWidth * sqrt(2))
    }
}

