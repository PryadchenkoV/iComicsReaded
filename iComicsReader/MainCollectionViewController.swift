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
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.toolbar.isHidden = true
        self.navigationController?.setToolbarHidden(true, animated: false)
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
        let uuid = ComicsGetter.shared.arrayOfComics[indexPath.item]
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return cell
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Comics")
        
        fetchRequest.predicate = NSPredicate(format: "uuid = %@",
                                             argumentArray: [uuid])
        fetchRequest.propertiesToFetch = ["firstPage"]
        fetchRequest.resultType = .dictionaryResultType
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            
            
            if let data = results.first?.allValues.first as? Data, let previewImage = UIImage(data: data) {
                cell.previewImage.image = previewImage
                cell.blurImage.image = previewImage
                cell.progressIndicator.stopAnimating()
            } else {
                cell.previewImage.image = nil
                cell.blurImage.image = nil
                cell.progressIndicator.startAnimating()
            }
        }
        catch {
            print("MainCollectionViewController: error creating cell \(error.localizedDescription)")
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
        return CGSize(width: cellWidth - 10, height: cellWidth * sqrt(2))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let nextViewController = ComicsPageViewController(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        nextViewController.comicsUUID = ComicsGetter.shared.arrayOfComics[indexPath.item]
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}

