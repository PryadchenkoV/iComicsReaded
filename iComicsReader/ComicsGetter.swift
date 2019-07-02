//
//  ComicsGetter.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 28/10/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//

import UIKit
import CoreData
import CoreML
import Vision

let kTypeOfComicsDefinedNotificationName: NSNotification.Name = NSNotification.Name(rawValue: "TypeOfComicsDefined")

typealias closureCallback = (Dictionary<String, Any>) -> ()

class ComicsGetter: NSObject {
    
    static let shared = ComicsGetter()
    
    var arrayOfComics = [NSManagedObject]()
    
    let unarchiver = Unarchiver.sharedInstance()
    
    override init() {
        super.init()
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Comics")
        do {
            arrayOfComics = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        NotificationCenter.default.addObserver(self, selector: #selector(setComicsType(notification:)), name: kTypeOfComicsDefinedNotificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addComics(withPath path: String) {
        let url = URL(fileURLWithPath: path)
        
        DispatchQueue.main.async {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            let entity =
                NSEntityDescription.entity(forEntityName: "Comics",
                                           in: managedContext)!
            
            let comics = NSManagedObject(entity: entity,
                                         insertInto: managedContext)
            
            let uuid = UUID()
            
            comics.setValue(uuid, forKey: "uuid")
            comics.setValue(url.lastPathComponent, forKeyPath: "name")
            self.willChangeValue(forKey: "arrayOfComics")
            self.arrayOfComics.append(comics)
            self.didChangeValue(forKey: "arrayOfComics")
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            self.unarchiver.readArchive(forPath: url, with: uuid, withComplitionBlock: { (arrayOfData, uuid) in
                guard let firstPage = arrayOfData[0] as? Data else {
                    print("[ComicsGetter] First Page is nil")
                    return
                }
                DispatchQueue.main.async {
                    guard let appDelegate =
                        UIApplication.shared.delegate as? AppDelegate else {
                            return
                    }
                    let managedContext =
                        appDelegate.persistentContainer.viewContext
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comics")
                    
                    fetchRequest.predicate = NSPredicate(format: "uuid = %@",
                                                         argumentArray: [uuid])
                    
                    do {
                        let results = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
                        if let results = results {
                            ComicsGetter.shared.willChangeValue(forKey: "arrayOfComics")
                            results.first?.setValue(firstPage, forKey: "firstPage")
                            results.first?.setValue(NSKeyedArchiver.archivedData(withRootObject: arrayOfData), forKey: "arrayOfData")
                            ComicsGetter.shared.didChangeValue(forKey: "arrayOfComics")
                        }
                    } catch {
                        print("Fetch Failed: \(error)")
                    }
                    do {
                        try managedContext.save()
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
                    ComicsGetter.shared.defineTypeOfComics(withUUID: uuid)
                }
            })
        }
    }
    
    @objc func setComicsType(notification: Notification)
    {
        if let userInfo = notification.userInfo as? [String: Any], let uuid = userInfo["uuid"] as? UUID, let type = userInfo["type"] as? String {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            let managedContext =
                appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comics")
            
            fetchRequest.predicate = NSPredicate(format: "uuid = %@",
                                                 argumentArray: [uuid])
            
            do {
                let results = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
                if let results = results {
                    results.first?.setValue(type, forKey: "type")
                }
            } catch {
                print("Fetch Failed: \(error)")
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func defineTypeOfComics(withUUID uuid: UUID) {
        var resultType = 0
        let numberOfTries = 5
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        DispatchQueue.global(qos: .background).async {
            do {
                let managedContext =
                    appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comics")
                
                fetchRequest.predicate = NSPredicate(format: "uuid = %@",
                                                     argumentArray: [uuid])
                
                do {
                    let results = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
                    guard let data = results?.first?.value(forKey: "arrayOfData") as? Data, let arrayOfData = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Data] else {
                        print("ComicsGetter: can't unarchive objects")
                        return
                    }
                    let group = DispatchGroup()
                    for _ in 0..<numberOfTries {
                        let pageNumber = Int.random(in: 0..<arrayOfData.count)
                        guard let uiImage = UIImage(data: arrayOfData[pageNumber]), let ciImage = CIImage(image: uiImage) else {
                            print("ComiscGetter: can't get Image")
                            return
                        }
                        guard let model = try? VNCoreMLModel(for: MangaWesternClassifier().model) else {
                            fatalError("ComiscGetter: Can't get ML Model")
                        }
                        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                            guard let results = request.results as? [VNClassificationObservation],
                                let topResult = results.first else {
                                    fatalError("unexpected result type from VNCoreMLRequest")
                            }
                            print("TOP RESULT: \(topResult.identifier)")
                            if topResult.identifier == "Manga" {
                                resultType += 1
                            }
                            group.leave()
                        })
                        group.enter()
                        let handler = VNImageRequestHandler(ciImage: ciImage)
                        DispatchQueue.global(qos: .userInteractive).async {
                            do {
                                try handler.perform([request])
                            } catch {
                                print(error)
                            }
                        }
                    }
                    group.notify(queue: DispatchQueue.main, execute: {
                        if Double(resultType) > (Double(numberOfTries)/2.0) {
                            NotificationCenter.default.post(name: kTypeOfComicsDefinedNotificationName, object: nil, userInfo: ["uuid": uuid, "type": "Manga"])
                            print("This is Mange")
                        } else {
                            NotificationCenter.default.post(name: kTypeOfComicsDefinedNotificationName, object: nil, userInfo: ["uuid": uuid, "type": "Western"])
                            print("This is Western")
                        }
                    })
                } catch {
                    print("Error while setting type: \(error.localizedDescription)")
                }
            }
        }
    }
    
}
