//
//  PopoverMenuViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 13/11/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//

import UIKit
import CoreData

class PopoverMenuViewController: UIViewController {

    @IBOutlet weak var segmentControllerLandscapeMode: UISegmentedControl!
    @IBOutlet weak var segmentedControllerBGColor: UISegmentedControl!
    @IBOutlet weak var mangaModeSwitch: UISwitch!
    @IBOutlet weak var closeButton: UIButton!
    
    var dictionaryPreferencesPlist: NSMutableDictionary!
    var dictionaryComicsPreferencesPlist: NSMutableDictionary!
    var filePreferencesPath = ""
    var uuid: UUID?
    var isManga = false
    var completionBlock: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let uerDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, uerDomainMask, true)
        guard let dirPath = paths.first else { return }
        filePreferencesPath = dirPath + "/Preferences.plist"
        dictionaryPreferencesPlist = NSMutableDictionary(contentsOfFile: filePreferencesPath)
        
        if let colorNumber = dictionaryPreferencesPlist["Comics Background Theme"] as? Int {
            segmentedControllerBGColor.selectedSegmentIndex = colorNumber
        }
        
        mangaModeSwitch.isOn = isManga
    }
    
    override var preferredContentSize: CGSize {
        get {
            let size = CGSize(width: 350, height: 400)
            return size
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    @IBAction func closeButtonPushed(_ sender: Any) {
        self.dismiss(animated: true, completion: { self.completionBlock?() })
    }
    
    @IBAction func segmentControlPageNumber(_ sender: UISegmentedControl) {
        dictionaryPreferencesPlist.setValue(sender.selectedSegmentIndex, forKey: "Landscape Page Number")
        dictionaryPreferencesPlist.write(toFile: filePreferencesPath, atomically: true)
        NotificationCenter.default.post(name: kNotificationNameBackGroundColorChanged, object: nil)
    }
    
    @IBAction func segmentControlBGColorPushed(_ sender: UISegmentedControl) {
        dictionaryPreferencesPlist.setValue(sender.selectedSegmentIndex, forKey: "Comics Background Theme")
        dictionaryPreferencesPlist.write(toFile: filePreferencesPath, atomically: true)
        NotificationCenter.default.post(name: kNotificationNameBackGroundColorChanged, object: nil)
    }
    
    @IBAction func mangaSwitchPushed(_ sender: Any) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate, let uuid = uuid else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let batchRequest = NSBatchUpdateRequest(entityName: "Comics")
        batchRequest.predicate = NSPredicate(format: "uuid = %@",
                                             argumentArray: [uuid])
        batchRequest.propertiesToUpdate = [#keyPath(Comics.type): isManga ? "Western" : "Manga"
        ]
        batchRequest.affectedStores = managedContext.persistentStoreCoordinator?.persistentStores
        
        batchRequest.resultType = .updatedObjectIDsResultType
        
        do {
            guard let butchResult = try managedContext.execute(batchRequest) as? NSBatchUpdateResult, let arrayOfUUID = butchResult.result as? [NSManagedObjectID] else {
                return
            }
            if arrayOfUUID.count > 0 {
                for objectID in arrayOfUUID {
                    var object: NSManagedObject?
                    do {
                        object = try managedContext.existingObject(with: objectID)
                        if let object = object {
                            managedContext.refresh(object, mergeChanges: true)
                        }
                    } catch  {
                        print("Refresh Failed: \(error)")
                    }
                }
                NotificationCenter.default.post(name: kNotificationNameComicsTypeChanged, object: nil)
                isManga = !isManga
                mangaModeSwitch.isOn = isManga
            }
        } catch {
            print("Batch Failed: \(error)")
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
