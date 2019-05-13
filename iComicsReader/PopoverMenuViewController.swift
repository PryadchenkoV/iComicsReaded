//
//  PopoverMenuViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 13/11/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//

import UIKit

class PopoverMenuViewController: UIViewController {

    @IBOutlet weak var segmentedControllerBGColor: UISegmentedControl!
    @IBOutlet weak var mangaModeSwitch: UISwitch!
    
    var dictionaryPreferencesPlist: NSMutableDictionary!
    var dictionaryComicsPreferencesPlist: NSMutableDictionary!
    var filePreferencesPath = ""
    var comicsName = ""
    
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
//        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
//        let blurEffectView = UIVisualEffectView(effect: blurEffect)
//        blurEffectView.frame = view.bounds
//        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.addSubview(blurEffectView)
//        view.sendSubviewToBack(blurEffectView)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func segmentControlBGColorPushed(_ sender: UISegmentedControl) {
        dictionaryPreferencesPlist.setValue(sender.selectedSegmentIndex, forKey: "Comics Background Theme")
        dictionaryPreferencesPlist.write(toFile: filePreferencesPath, atomically: true)
        NotificationCenter.default.post(name: kNotificationNameBackGroundColorChanged, object: nil)
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
