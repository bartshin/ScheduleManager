//
//  StickerCell.swift
//  PixelScheduler
//
//  Created by Shin on 4/22/21.
//

import UIKit

class StickerCell: UICollectionViewCell {
    
    static let reuseID = "StickerCell"
    
    var sticker: Sticker! {
        didSet {
            stickerImageView.image = sticker.image
        }
    }
    
    @IBOutlet weak var stickerImageView: UIImageView!
    
}
