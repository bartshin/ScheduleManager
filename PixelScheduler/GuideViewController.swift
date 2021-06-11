//
//  GuideViewController.swift
//  PixelScheduler
//
//  Created by bart Shin on 09/06/2021.
//

import UIKit

class GuideViewController: UIViewController {
	
	@IBOutlet weak var titleLabel: PaddingLabel!
	@IBOutlet private weak var textView: UITextView!
	@IBOutlet private weak var scrollView: UIScrollView!
	@IBOutlet private weak var pageControl: UIPageControl!
	
	var guides = [Guide]()
	fileprivate var imageViews = [UIImageView]()
	
	@objc fileprivate func tapPageControl(_ sender: UIPageControl) {
		scrollView.scrollRectToVisible(imageViews[sender.currentPage].frame, animated: true)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		titleLabel.text = guides.first?.title
		textView.text = guides.first?.text
		titleLabel.font = UIFont(name: "YANGJIN", size: 18)
		textView.font = UIFont.systemFont(ofSize: 15)
		scrollView.delegate = self
		pageControl.addTarget(self, action: #selector(tapPageControl(_:)), for: .valueChanged)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		scrollView.contentSize = CGSize(
			width: scrollView.bounds.width * CGFloat(guides.count),
			height: scrollView.bounds.height)
		guides.enumerated().forEach { (index, guide) in
			let imageView = UIImageView(image: guide.image)
			let origin = CGPoint(x: scrollView.bounds.width * CGFloat(index),
													 y: scrollView.bounds.origin.y)
			imageView.contentMode = .scaleAspectFit
			imageView.frame = CGRect(origin: origin,
															 size: scrollView.bounds.size)
			scrollView.addSubview(imageView)
			imageViews.append(imageView)
		}
	}
	
	struct Guide {
		let title: String
		let text: String
		let image: UIImage
	}
}

extension GuideViewController: UIScrollViewDelegate {
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if let index = imageViews.firstIndex(where: {
			$0.frame.contains(scrollView.contentOffset)
		}) {
			titleLabel.text = guides[index].title
			textView.text = guides[index].text
			pageControl.currentPage = index
		}
	}
}
