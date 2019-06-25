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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ComicsGetter.shared.removeObserver(self, forKeyPath: "arrayOfComics")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ComicsGetter.shared.addObserver(self, forKeyPath: "arrayOfComics", options: [], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "arrayOfComics" {
            collectionView.reloadData()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ComicsGetter.shared.arrayOfComics.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: comiscCellId, for: indexPath) as? ComiscCollectionViewCell else {
            fatalError("Cell Not Created")
        }
        
        if let data = ComicsGetter.shared.arrayOfComics[indexPath.item].value(forKey: "data") as? [Data], let first = data.first, let previewImage = UIImage(data: first) {
            cell.previewImage.image = previewImage
            cell.blurImage.image = previewImage
        } else {
            cell.previewImage.image = nil
            cell.blurImage.image = nil
        }
        
        return cell
    }
    
    @IBAction func openComics(_ sender: Any) {
        performSegue(withIdentifier: "fromCollectionToPages", sender: sender)
    }

}

extension MainCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat =  19
        let cellWidth = (UIApplication.shared.delegate as! AppDelegate).screenWidth / 2 - padding
        return CGSize(width: cellWidth, height: cellWidth * sqrt(2))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let nextViewController = ComicsPageViewController()
        nextViewController.comicsInstance = ComicsGetter.shared.arrayOfComics[indexPath.item]
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}

