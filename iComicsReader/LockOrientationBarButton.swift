//
//  LockOrientationBarButton.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 12/11/2018.
//  Copyright © 2018 MIEM. All rights reserved.
//

import UIKit

class LockOrientationBarButton: UIButton {
    
    var imageRotation: UIImageView!
    var imageLockUnlock: UIImageView!
    var customView: UIView!
    var isUnlock = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageRotation = UIImageView(image: #imageLiteral(resourceName: "Rotation"))
        imageRotation.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        imageRotation.transform = imageRotation.transform.rotated(by: CGFloat(Double.pi / 4))
        imageLockUnlock = UIImageView(image: #imageLiteral(resourceName: "Unlock"))
        imageLockUnlock.frame = CGRect(x: 8, y: 8, width: 16, height: 16)
        self.addSubview(imageRotation)
        self.addSubview(imageLockUnlock)
        self.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func buttonPressed() {
        UIView.animate(withDuration: 1.5, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.imageRotation.transform = self.imageRotation.transform.rotated(by: CGFloat(Double.pi))
            self.imageRotation.transform = self.imageRotation.transform.rotated(by: CGFloat(Double.pi))
        }, completion: nil)
        UIView.transition(with: self.imageLockUnlock, duration: 0.75, options: [.curveLinear], animations: {
            if self.isUnlock {
                self.imageLockUnlock.image = #imageLiteral(resourceName: "Lock")
                self.imageLockUnlock.tintColor = UIColor.red
                self.imageRotation.tintColor = UIColor.red
            } else {
                self.imageLockUnlock.image = #imageLiteral(resourceName: "Unlock")
                self.imageLockUnlock.tintColor = nil
                self.imageRotation.tintColor = nil
            }
        }, completion: { _ in self.isUnlock = !self.isUnlock})
    }
    
    

}
