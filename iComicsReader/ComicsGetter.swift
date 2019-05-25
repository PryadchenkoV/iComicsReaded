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

typealias closureCallback = (Dictionary<String, Any>) -> ()

class ComicsGetter: NSObject {
    
    static let shared = ComicsGetter()
    
    var arrayOfComics = [NSManagedObject]()
    
    let unarchiver = Unarchiver.sharedInstance()
    
    override init() {
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
    }
    
    func addComics(withPath path: URL) {
        unarchiver.readArchive(forPath: path) { (dictionary) in
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
                
                
                comics.setValue(dictionary["Name"], forKeyPath: "name")
                comics.setValue(dictionary["Data"], forKey: "data")
                
                ComicsGetter.shared.defineTypeOf(comics: comics, withComplitionBlock: { (obj, type) in
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Comics")
                    
                    fetchRequest.predicate = NSPredicate(format: "data = %@ AND name = %@",
                                                         argumentArray: [obj.value(forKey: "data"), obj.value(forKey: "name")])
                    
                    do {
                        let results = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
                        if results?.count != 0 {
                            results![0].setValue(type, forKey: "type")
                        }
                    } catch {
                        print("Fetch Failed: \(error)")
                    }
                    
                    do {
                        try managedContext.save()
                        if let index = ComicsGetter.shared.arrayOfComics.firstIndex(where: {
                            if let elementName = $0.value(forKey: "name") as? String, let objName = obj.value(forKey: "name") as? String, let elementData = $0.value(forKey: "data") as? [Data], let objData = obj.value(forKey: "data") as? [Data] {
                                return elementName == objName && elementData == objData
                            }
                            return false
                        }) {
                            ComicsGetter.shared.arrayOfComics[index].setValue(type, forKey: "type")
                        }
                    }
                    catch {
                        print("Saving Core Data Failed: \(error)")
                    }
                })
                
                do {
                    try managedContext.save()
                    ComicsGetter.shared.arrayOfComics.append(comics)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    func defineTypeOf(comics: NSManagedObject, withComplitionBlock block: @escaping (NSManagedObject, String)->()) {
        guard let imageArray = comics.value(forKey: "Data") as? [Data] else {
            print("ComiscGetter: Can't fetch Data from NSManagedObject")
            return
        }
        var resultType = 0
        let numberOfTries = 5
        DispatchQueue.global(qos: .background).async {
            let group = DispatchGroup()
            for _ in 0..<numberOfTries {
                let pageNumber = Int.random(in: 0..<imageArray.count)
                guard let uiImage = UIImage(data: imageArray[pageNumber]), let ciImage = CIImage(image: uiImage) else {
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
                    block(comics,"Mange")
                    print("This is Mange")
                } else {
                    block(comics,"Western")
                    print("This is Western")
                }
            })
        }
    }
    
}
