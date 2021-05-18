//
//  StickerSelectVC.swift
//  PixelScheduler
//
//  Created by Shin on 4/22/21.
//

import UIKit

class StickerSelectVC: UIViewController {
    
    var palette: SettingController.ColorPalette!
    
    private let allStampCollection: [Sticker.Collection] = Sticker.Collection.allCases
    
    private var selectedCollection: Sticker.Collection = .celebration {
        didSet {
            stickerCollectionView.reloadData()
        }
    }
    var selectedSticker: Sticker? {
        didSet{
            selectedCollection = selectedSticker!.collection
            collectionPicker.selectRow(allStampCollection.firstIndex(of: selectedCollection)!, inComponent: 0, animated: false)
        }
    }
    
    private let numberOfStampsInCollection = 10
    
    @IBOutlet private weak var collectionPicker: UIPickerView!
    @IBOutlet private weak var stickerCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionPicker.delegate = self
        collectionPicker.dataSource = self
        stickerCollectionView.dataSource = self
        stickerCollectionView.delegate = self
        stickerCollectionView.allowsMultipleSelection = false
    }
    
    func drawCustomView(in alert: UIAlertController) {
        alert.setValue(self, forKey: "contentViewController")
        view.widthAnchor.constraint(equalToConstant: alert.view.bounds.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: 400).isActive = true
    }
}

extension StickerSelectVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfStampsInCollection
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 80, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCell.reuseID, for: indexPath) as! StickerCell
        cell.sticker = Sticker(collection: selectedCollection, number: indexPath.row + 1)
        if cell.sticker == selectedSticker {
            cell.layer.cornerRadius = 20
            cell.backgroundColor = palette.secondary
        }else {
            cell.backgroundColor = nil
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        if let previousSelcection = stickerCollectionView.indexPathsForSelectedItems?.first,
           let oldCell = collectionView.cellForItem(at: previousSelcection) as? StickerCell {
            oldCell.backgroundColor = nil
        }
        
        if let newCell = collectionView.cellForItem(at: indexPath) as? StickerCell {
            selectedSticker = newCell.sticker
            newCell.layer.cornerRadius = 20
            newCell.backgroundColor = palette.secondary
        }
        return true
    }
}

extension StickerSelectVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        allStampCollection.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        20
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        allStampCollection[row].koreanName
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCollection = allStampCollection[row]
        
    }
}
