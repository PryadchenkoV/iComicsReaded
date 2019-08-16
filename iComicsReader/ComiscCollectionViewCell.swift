//
//  ComiscCollectionViewCell.swift
//  iComicsReader
//
//  Created by Ivan Pryadchenko on 10/04/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit

class ComiscCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var blurImage: UIImageView!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var previewImage: UIImageView!
 
    override func awakeFromNib() {
        super.awakeFromNib()
        self.progressIndicator.startAnimating()
        self.contentView.layer.cornerRadius = 10.0
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.borderColor = UIColor.black.cgColor
        self.contentView.layer.masksToBounds = true
        self.contentView.layer.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        addObserver(self, forKeyPath: "previewImage.image", options: [], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath! == "previewImage.image" {
            if let image = self.previewImage.image {
                self.previewImage.contentMode = (image.size.width > image.size.height ? UIImageView.ContentMode.scaleAspectFit : UIImageView.ContentMode.scaleAspectFill)
            }
        } else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    deinit {
        removeObserver(self, forKeyPath: "previewImage.image")
    }
    
}
