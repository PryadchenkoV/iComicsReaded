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
                if let destPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                      .userDomainMask,
                                                                      true).first {
                    let dirName = uuid.uuidString
                    let fullDirPath = URL(fileURLWithPath: destPath)
                        .appendingPathComponent(dirName)
                    
                    do {
                        try FileManager.default.createDirectory(atPath: fullDirPath.path, withIntermediateDirectories: false, attributes: nil)
                        for (index, data) in arrayOfData.enumerated() {
                            guard let data = data as? Data else {
                                print("[ComicsGetter] Error creating data from array")
                                continue
                            }
                            let image = UIImage(data: data)
                            if let pngData = image?.pngData() {
                                try pngData.write(to: fullDirPath.appendingPathComponent("\(index).png"), options: .atomic)
                            }
                        }
                    } catch let error as NSError {
                        fatalError("Cannot create dir or write files")
                    }
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
                                results[0].setValue(firstPage, forKey: "firstPage")
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
                        ComicsGetter.shared.defineTypeOfComics(withUrl: fullDirPath)
                    }
                }
            })
        }
    }
    
    @objc func setComicsType(notification: Notification)
    {
        if let userInfo = notification.userInfo as? [String: Any], let url = userInfo["url"] as? URL, let type = userInfo["type"] as? String {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            let managedContext =
                appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comics")
            
            fetchRequest.predicate = NSPredicate(format: "pathToArchive = %@",
                                                 argumentArray: [url])
            
            do {
                let results = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
                if let results = results {
                    results[0].setValue(type, forKey: "type")
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
    
    func defineTypeOfComics(withUrl url: URL) {
        var resultType = 0
        let numberOfTries = 5
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                let group = DispatchGroup()
                for _ in 0..<numberOfTries {
                    let pageNumber = Int.random(in: 0..<fileURLs.count)
                    guard let uiImage = UIImage(contentsOfFile: fileURLs[pageNumber].absoluteString), let ciImage = CIImage(image: uiImage) else {
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
                        NotificationCenter.default.post(name: kTypeOfComicsDefinedNotificationName, object: nil, userInfo: ["url": url, "type": "Manga"])
                        print("This is Mange")
                    } else {
                        NotificationCenter.default.post(name: kTypeOfComicsDefinedNotificationName, object: nil, userInfo: ["url": url, "type": "Western"])
                        print("This is Western")
                    }
                })
            } catch {
                print("Error while enumerating files \(url.path): \(error.localizedDescription)")
            }
        }
    }
    
}
