//
//  ViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 23/10/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//
import UIKit


class ShowPageViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    var page = 0
    
    var comicsArray = [[String : Any]]() {
        didSet(value) {
            self.comicsArray.sort { ($0["PageNumber"] as! Int) > ($1["PageNumber"] as! Int)}
            guard let data = comicsArray[page]["PageData"] as? Data else { return }
            DispatchQueue.main.async {
                self.imageView.image = UIImage(data: data)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let filePath = Bundle.main.path(forResource: "SecretWars00", ofType: "cbr") {
            let unarchiver = Unarchiver.sharedInstance()
            unarchiver.addObserver(self, forKeyPath: "arrayOfComics", options: [], context: nil)
            unarchiver.readArchive(forPath: filePath)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath! == "arrayOfComics"
        {
            guard let archive = Unarchiver.sharedInstance().arrayOfComics as? [[String : Any]] else { return }
            comicsArray = archive
            
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func changePageTo(_ page: Int, withTransitionOption option: UIView.AnimationOptions) {
        guard let data = comicsArray[page]["PageData"] as? Data else { return }
        UIView.transition(with: imageView, duration: 0.2, options: option, animations: { self.imageView.image = UIImage(data: data) }, completion: nil)
    }
    
    @IBAction func changePageToNext(_ sender: Any) {
        page = page < comicsArray.count - 1 ? page + 1 : comicsArray.count - 1
        changePageTo(page, withTransitionOption: [.transitionCrossDissolve, .curveEaseInOut])
    }
    
    @IBAction func changePageToPrevious(_ sender: Any) {
        page = page > 0 ? page - 1 : 0
        changePageTo(page, withTransitionOption: [.transitionCrossDissolve, .curveEaseInOut])
    }
}

