//
//  ViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 23/10/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//
import UIKit

let kNotificationNameBackGroundColorChanged: NSNotification.Name = NSNotification.Name(rawValue: "BGColorChanged")

// MARK: Extensions

extension ShowPageViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension UIImage {
    /// Get the pixel color at a point in the image
    func pixelColor(atLocation point: CGPoint) -> UIColor? {
        let cgImage : CGImage = self.cgImage!
        guard let pixelData = CGDataProvider(data: (cgImage.dataProvider?.data)!)?.data else {
            return UIColor.clear
        }
        let data = CFDataGetBytePtr(pixelData)!
        let x = Int(point.x)
        let y = Int(point.y)
        let index = Int(self.size.width) * y + x
        let expectedLengthA = Int(self.size.width * self.size.height)
        let expectedLengthRGB = 3 * expectedLengthA
        let expectedLengthRGBA = 4 * expectedLengthA
        let numBytes = CFDataGetLength(pixelData)
        switch numBytes {
        case expectedLengthA:
            return UIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(data[index])/255.0)
        case expectedLengthRGB:
            return UIColor(red: CGFloat(data[3*index])/255.0, green: CGFloat(data[3*index+1])/255.0, blue: CGFloat(data[3*index+2])/255.0, alpha: 1.0)
        case expectedLengthRGBA:
            return UIColor(red: CGFloat(data[4*index])/255.0, green: CGFloat(data[4*index+1])/255.0, blue: CGFloat(data[4*index+2])/255.0, alpha: CGFloat(data[4*index+3])/255.0)
        default:
            // unsupported format
            return UIColor.clear
        }
    }
}

class ShowPageViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    
    // MARK: IBOutlet
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lockOrientationToolBarItem: UIBarButtonItem!
    @IBOutlet weak var buttonShowMenuPopover: UIBarButtonItem!
    
    // MARK: Variables
    var page = 0
    var isAutorotationUnlocked = true
    var comicsArray = [[String : Any]]() {
        didSet(value) {
            self.comicsArray.sort { ($0["PageNumber"] as! Int) > ($1["PageNumber"] as! Int)}
            guard let data = comicsArray[page]["PageData"] as? Data else { return }
            DispatchQueue.main.async {
                self.changeTitle()
                self.imageView.image = UIImage(data: data)
                self.view.backgroundColor = self.getColorForBackgound()
            }
        }
    }
    
    let unarchiver = Unarchiver.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        let doubleTapGuest = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView(recognizer:)))
        doubleTapGuest.numberOfTapsRequired = 2
        let singleTapGuest = UITapGestureRecognizer(target: self, action: #selector(handleSingleTapGuesture(recognizer:)))
        scrollView.addGestureRecognizer(doubleTapGuest)
        scrollView.addGestureRecognizer(singleTapGuest)
    
        self.changeTitle()
        self.setupCustomBarItem()
        
        if let filePath = Bundle.main.path(forResource: "SecretWars00", ofType: "cbr") {
            unarchiver.addObserver(self, forKeyPath: "arrayOfComics", options: [], context: nil)
            unarchiver.readArchive(forPath: filePath)
        }
        
        navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(setBGColor), name: kNotificationNameBackGroundColorChanged, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unarchiver.removeObserver(self, forKeyPath: "arrayOfComics")
        unarchiver.cancelTask()
        NotificationCenter.default.removeObserver(self)
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    @objc func viewForZooming(in scrollView: UIScrollView) -> UIView? {
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
    
    // MARK: Usefull functions
    
    func changeTitle() {
        var viewTitle = ""
        if comicsArray.count == 0 {
            viewTitle = NSLocalizedString("Loading...", comment: "")
        } else {
            viewTitle = NSLocalizedString("%d of %d", comment: "")
        }
        self.title = String(format: viewTitle, self.page + 1, self.comicsArray.count)
    }
    
    func changePageTo(_ page: Int, withTransitionOption option: UIView.AnimationOptions) {
        guard let data = comicsArray[page]["PageData"] as? Data else { return }
        UIView.transition(with: imageView, duration: 0.2, options: option, animations: {
            self.imageView.image = UIImage(data: data)
            self.setBGColor()
        }, completion: nil)
        self.changeTitle()
    }
    
    @objc func setBGColor() {
        self.view.backgroundColor = self.getColorForBackgound()
    }
    
    func getColorForBackgound() -> UIColor {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let uerDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, uerDomainMask, true)
        guard let dirPath = paths.first else { return UIColor.white }
        let dictionaryInfoPlist = NSDictionary(contentsOfFile: dirPath + "/Preferences.plist")
        guard let colorNumber = dictionaryInfoPlist?["Comics Background Theme"] as? Int else {
            return UIColor.white
        }
        
        if colorNumber == 0 {
            return UIColor.white
        } else if colorNumber == 1 {
            return UIColor.black
        } else {
            guard let imageSize = imageView.image?.size else { return UIColor.white }
            let arrayOfPoints = [CGPoint(x: 1, y: 1), CGPoint(x: imageSize.width/2.0, y: 1), CGPoint(x: imageSize.width - 1, y: 1), CGPoint(x: 1, y: imageSize.height - 1), CGPoint(x: imageSize.width/2.0, y: imageSize.height - 1), CGPoint(x: imageSize.width - 1, y: imageSize.height - 1)]
            var arrayOfColors = [UIColor]()
            for point in arrayOfPoints {
                if let color = imageView.image?.pixelColor(atLocation: point) {
                    arrayOfColors.append(color)
                }
            }
            
            var red: CGFloat = 0.0;
            var green: CGFloat = 0.0;
            var blue: CGFloat = 0.0;
            var alpha: CGFloat = 0.0
            
            for color in arrayOfColors {
                red += CIColor(cgColor: color.cgColor).red
                green += CIColor(cgColor: color.cgColor).green
                blue += CIColor(cgColor: color.cgColor).blue
                alpha += CIColor(cgColor: color.cgColor).alpha
            }
            return UIColor(red: red/CGFloat(arrayOfColors.count), green: green/CGFloat(arrayOfColors.count), blue: blue/CGFloat(arrayOfColors.count), alpha: alpha/CGFloat(arrayOfColors.count))
        }
    }
    
    func setupCustomBarItem() {
        lockOrientationToolBarItem.customView = LockOrientationBarButton(withAction: {
            self.isAutorotationUnlocked = !self.isAutorotationUnlocked
            self.lockOrientationButtonPushed(self)
        })
    }
    
    // MARK: IBActions
    
    @IBAction func changePageToNext(_ sender: Any) {
        page = page < comicsArray.count - 1 ? page + 1 : comicsArray.count - 1
        changePageTo(page, withTransitionOption: [.transitionCrossDissolve, .curveEaseInOut])
    }
    
    @IBAction func changePageToPrevious(_ sender: Any) {
        page = page > 0 ? page - 1 : 0
        changePageTo(page, withTransitionOption: [.transitionCrossDissolve, .curveEaseInOut])
    }
    
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    @IBAction func showMenuPopover(_ sender: Any) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopoverComicsSettings") else { return }
        popVC.modalPresentationStyle = .popover
        
        let popOverVC = popVC.popoverPresentationController
        popOverVC?.delegate = self
//        popOverVC?.sourceView = buttonView
//        popOverVC?.sourceRect = CGRect(x: buttonView.bounds.midX, y: buttonView.bounds.minY, width: 0, height: 0)
        popOverVC?.barButtonItem = buttonShowMenuPopover
        popOverVC?.permittedArrowDirections = .up
        
        self.present(popVC, animated: true)
    }
    
    @IBAction func lockOrientationButtonPushed(_ sender: Any) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        var uiViewOrientation = UIInterfaceOrientationMask.all
        if !isAutorotationUnlocked {
            switch UIDevice.current.orientation {
            case .portrait:
                uiViewOrientation = .portrait
            case .portraitUpsideDown:
                uiViewOrientation = .portraitUpsideDown
            case .landscapeLeft:
                uiViewOrientation = .landscapeLeft
            case .landscapeRight:
                uiViewOrientation = .landscapeRight
            default:
                uiViewOrientation = delegate.restrictRotation
            }
        }
        delegate.restrictRotation = uiViewOrientation
    }
    
    @IBAction func handleSingleTapGuesture(recognizer: UITapGestureRecognizer) {
        guard let navigationController = navigationController else { return }
        if navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(false, animated: true)
            navigationController.setNavigationBarHidden(false, animated: true)
        } else {
            navigationController.setToolbarHidden(true, animated: true)
            navigationController.setNavigationBarHidden(true, animated: true)
        }
    }
}
