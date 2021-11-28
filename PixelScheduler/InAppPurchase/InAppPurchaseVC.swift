//
//  InAppPurchaseVC.swift
//  PixelScheduler
//
//  Created by Shin on 4/13/21.
//

import UIKit
import StoreKit
import AVFoundation

class InAppPurchaseVC: UITableViewController
//, PlaySoundEffect
{
	
	var settingController: SettingController!
	
	@IBOutlet weak var purchaseButton: UIButton!
	private var product: SKProduct?
	var player: AVAudioPlayer!
	
	@IBAction func tapPurchaseButton(_ sender: UIButton) {
		if product != nil {
			InAppProducts.store.buyProduct(product!)
		}else {
			showAlertForDismiss(
				title: "구매 실패",
				message: "앱 스토어와 연결에 실패 하였습니다",
				with: settingController.visualMode)
		}
	}
	@IBAction func tapRestoreButton(_ sender: UIButton) {
		InAppProducts.store.restorePurchases()
	}
	
	@objc func feedbackForPurchaseOrRestore() {
		let hapticGenerator = UIImpactFeedbackGenerator()
		hapticGenerator.prepare()
//		playSound(AVAudioPlayer.coin)
		showAlertForDismiss(title: "감사합니다", message: "프리미엄 패키지를 이용할 수 있습니다", with: settingController.visualMode)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		if settingController.isPurchased {
			purchaseButton.isEnabled = false
			purchaseButton.setTitle("프리미엄 이용중", for: .normal)
			purchaseButton.setImage(nil, for: .normal)
		}
		settingController.observePurchase()
		NotificationCenter.default.addObserver(
			self, selector: #selector(feedbackForPurchaseOrRestore), name: .IAPHelperPurchaseNotification, object: nil)
		InAppProducts.store.requestProducts { success, products in
			if success, products != nil {
				self.product = products!.first
			}
		}
	}
	
}
