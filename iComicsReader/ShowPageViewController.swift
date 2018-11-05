//
//  ViewController.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 23/10/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//
import UIKit

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

class ShowPageViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: IBOutlet
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // MARK: Variables
    var page = 0
    var comicsArray = [[String : Any]]() {
        didSet(value) {
            self.comicsArray.sort { ($0["PageNumber"] as! Int) > ($1["PageNumber"] as! Int)}
            guard let data = comicsArray[page]["PageData"] as? Data else { return }
            DispatchQueue.main.async {
                self.imageView.image = UIImage(data: data)
                self.scrollView.backgroundColor = self.getColorForBackgound()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        let doubleTapGuest = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView(recognizer:)))
        doubleTapGuest.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGuest)
        
        if let filePath = Bundle.main.path(forResource: "SecretWars00", ofType: "cbr") {
            let unarchiver = Unarchiver.sharedInstance()
            unarchiver.addObserver(self, forKeyPath: "arrayOfComics", options: [], context: nil)
            unarchiver.readArchive(forPath: filePath)
        }
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
    
    func changePageTo(_ page: Int, withTransitionOption option: UIView.AnimationOptions) {
        guard let data = comicsArray[page]["PageData"] as? Data else { return }
        UIView.transition(with: imageView, duration: 0.2, options: option, animations: {
            self.imageView.image = UIImage(data: data)
            self.scrollView.backgroundColor = self.getColorForBackgound()
        }, completion: nil)
    }
    
    func getColorForBackgound() -> UIColor {
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
}
