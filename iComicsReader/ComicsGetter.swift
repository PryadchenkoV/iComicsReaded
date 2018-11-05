//
//  ComicsGetter.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 28/10/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//

import UIKit

class ComicsGetter: NSObject {

    static let shared = ComicsGetter()
    
    let unarchiver = Unarchiver.sharedInstance()
    
    func setCurrentComics(url: URL) {
        unarchiver.addObserver(self, forKeyPath: "arrayOfComics", options: [], context: nil)
        unarchiver.readArchive(forPath: url.path)
        
    }
    
    deinit {
        unarchiver.removeObserver(self, forKeyPath: "arrayOfComics")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath! == "arrayOfComisc"
        {
            
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func getCurrentComiscPage(_ pageNumber: Int) {
//        do {
//            if let comics
//        }
    }
    
}
