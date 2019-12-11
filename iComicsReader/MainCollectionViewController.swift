//
//  MainCollectionViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 10/04/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit
import CoreData

class MainCollectionViewController: UIViewController, UICollectionViewDelegate {

    
    let comiscCellId = "ComicsView"
    let recentComicsCellId = "RecentComicsView"
    let comiscArray = [NSManagedObject]()
    @IBOutlet weak var collectionView: UICollectionView!
    let isRecentShown = ComicsGetter.shared.arrayOfRecentComics.count != 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ComicsGetter.shared.removeObserver(self, forKeyPath: "arrayOfComics")
        ComicsGetter.shared.removeObserver(self, forKeyPath: "arrayOfRecentComics")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
        ComicsGetter.shared.addObserver(self, forKeyPath: "arrayOfComics", options: [], context: nil)
        ComicsGetter.shared.addObserver(self, forKeyPath: "arrayOfRecentComics", options: [], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name("UIDeviceOrientationDidChangeNotification"), object: nil)
        
        ComicsGetter.shared.reloadRecentComics()
        self.collectionView.reloadData()
    }
    
    @objc func reload() {
        self.collectionView.reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "arrayOfComics" || keyPath == "arrayOfRecentComics" {
            collectionView.reloadData()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func deleteEntity(withUUID uuid: UUID?) {
        guard let uuid = uuid else {
            print("\(#function) UUID is nil")
            return
        }
        ComicsGetter.shared.deleteComics(withUUID: uuid) { [weak self](index) in
            self?.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            self?.collectionView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToComicsPageView" {
            guard let nextViewController = segue.destination as? ComicsPageViewController, let cell = sender as? ComicsCollectionViewCell else { return }
            nextViewController.comicsUUID = cell.uuid
            nextViewController.comicsDelegate = self
        }
    }

}

extension MainCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 && isRecentShown {
            
            let cellWidth = UIDevice.current.orientation == .portrait ? (UIApplication.shared.delegate as! AppDelegate).screenWidth : (UIApplication.shared.delegate as! AppDelegate).screenHeight
            return CGSize(width: cellWidth, height: 150)
        } else {
            let padding: CGFloat =  19
            let cellWidth = (UIApplication.shared.delegate as! AppDelegate).screenWidth / 2 - padding
            return CGSize(width: cellWidth - 10, height: cellWidth * sqrt(2))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 && isRecentShown {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            return UIEdgeInsets(top: 0, left: 19, bottom: 0, right: 19)
        }
    }
    
}

extension MainCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 && isRecentShown {
            return 1
        } else {
            return ComicsGetter.shared.arrayOfComics.count
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return isRecentShown ? 2 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isRecentShown && indexPath.section == 0 && indexPath.item == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: recentComicsCellId, for: indexPath) as? RecentCollectionViewCell else {
                fatalError("Cell Not Created")
            }
            cell.collectionView.reloadData()
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: comiscCellId, for: indexPath) as? ComicsCollectionViewCell else {
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
            fetchRequest.propertiesToFetch = ["firstPage", "isNew"]
            fetchRequest.resultType = .dictionaryResultType
            
            do {
                let results = try managedContext.fetch(fetchRequest)
                
                guard let dictionaryOfResult = results.first else {
                    return cell
                }
                if let data = dictionaryOfResult["firstPage"] as? Data, let previewImage = UIImage(data: data) {
                    cell.previewImage.image = previewImage
                    cell.blurImage.image = previewImage
                    cell.progressIndicator.stopAnimating()
                } else {
                    cell.previewImage.image = nil
                    cell.blurImage.image = nil
                    cell.progressIndicator.startAnimating()
                }
                
                cell.favoriteView.isHidden = !(dictionaryOfResult["isNew"] as! Bool)
                cell.uuid = uuid
            }
            catch {
                print("MainCollectionViewController: error creating cell \(error.localizedDescription)")
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as? HeaderMainCollectionViewCell else {
            fatalError()
        }
        if indexPath.section == 0 {
            header.headerTitle.text = "Recent"
        } else if indexPath.section == 1 {
            header.headerTitle.text = "All"
        }
        return header
    }
}

extension MainCollectionViewController: ComicsPageViewControllerDelegate {
    
    func comicsPageViewController(_ controller: ComicsPageViewController, didSelect action: UIPreviewAction, for previewController: UIViewController) {
        switch action.title {
        case "Delete":
            print("Delete")
            self.deleteEntity(withUUID: controller.comicsUUID)
        default:
            break
        }
    }
    
}
