//
//  Gif.swift
//  SwiftGif
//
//  Created by Arne Bahlo on 07.06.14.
//  Copyright (c) 2014 Arne Bahlo. All rights reserved.
//
import SwiftUI
import ImageIO

extension UIImageView {
	
	public func loadGif(name: String) {
		DispatchQueue.global().async {
			let image = UIImage.gif(name: name)
			DispatchQueue.main.async {
				self.image = image
				self.setNeedsDisplay()
			}
		}
	}
	
	@available(iOS 9.0, *)
	public func loadGif(asset: String) {
		DispatchQueue.global().async {
			let image = UIImage.gif(asset: asset)
			DispatchQueue.main.async {
				self.image = image
			}
		}
	}
	
}

class UIGIFImage: UIView {
	private let imageView = UIImageView()
	private var data: Data?
	private var name: String?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	convenience init(name: String) {
		self.init()
		self.name = name
		initView()
	}
	
	convenience init(data: Data) {
		self.init()
		self.data = data
		initView()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		imageView.frame = bounds
		self.addSubview(imageView)
	}
	
	func updateGIF(data: Data) {
		imageView.image = UIImage.gif(data: data)
	}
	
	func updateGIF(name: String) {
		imageView.image = UIImage.gif(name: name)
	}
	
	private func initView() {
		imageView.contentMode = .scaleAspectFit
	}
}

struct GIFImage: UIViewRepresentable {
	private let data: Data?
	private let name: String?
	
	init(data: Data) {
		self.data = data
		self.name = nil
	}
	
	public init(name: String) {
		self.data = nil
		self.name = name
	}
	
	func makeUIView(context: Context) -> UIGIFImage {
		if let data = data {
			return UIGIFImage(data: data)
		} else {
			return UIGIFImage(name: name ?? "")
		}
	}
	
	func updateUIView(_ uiView: UIGIFImage, context: Context) {
		if let data = data {
			uiView.updateGIF(data: data)
		} else {
			uiView.updateGIF(name: name ?? "")
		}
	}
}

extension UIImage {
	
	public class func getFramesFromGif(name: String) -> (frames: [UIImage], duration: Double)? {
		guard let data = getData(gifName: name) else {
			assertionFailure("Fail to load gif data for \(name)")
			return nil
		}
		guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
			print("SwiftGif: Source for the image does not exist")
			return nil
		}
		return getFramesAndDuration(from: imageSource)
		
	}
	
	public class func gif(data: Data) -> UIImage? {
		// Create source from data
		guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
			print("SwiftGif: Source for the image does not exist")
			return nil
		}
		
		return UIImage.animatedImageWithSource(source)
	}
	
	
	public class func gif(url: String) -> UIImage? {
		// Validate URL
		guard let bundleURL = URL(string: url) else {
			print("SwiftGif: This image named \"\(url)\" does not exist")
			return nil
		}
		
		// Validate data
		guard let imageData = try? Data(contentsOf: bundleURL) else {
			print("SwiftGif: Cannot turn image named \"\(url)\" into NSData")
			return nil
		}
		
		return gif(data: imageData)
	}
	
	fileprivate class func getData(gifName: String) -> Data? {
		guard let bundleURL = Bundle.main
						.url(forResource: gifName, withExtension: "gif") else {
							print("SwiftGif: This image named \"\(gifName)\" does not exist")
							return nil
						}
		
		// Validate data
		guard let imageData = try? Data(contentsOf: bundleURL) else {
			print("SwiftGif: Cannot turn image named \"\(gifName)\" into NSData")
			return nil
		}
		return imageData
	}
	
	public class func gif(name: String) -> UIImage? {
		// Check for existance of gif
		guard let data = getData(gifName: name) else {
			return nil
		}
		
		return gif(data: data)
	}
	
	@available(iOS 9.0, *)
	public class func gif(asset: String) -> UIImage? {
		// Create source from assets catalog
		guard let dataAsset = NSDataAsset(name: asset) else {
			print("SwiftGif: Cannot turn image named \"\(asset)\" into NSDataAsset")
			return nil
		}
		
		return gif(data: dataAsset.data)
	}
	
	internal class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
		var delay = 0.1
		
		// Get dictionaries
		let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
		let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
		defer {
			gifPropertiesPointer.deallocate()
		}
		let unsafePointer = Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
		if CFDictionaryGetValueIfPresent(cfProperties, unsafePointer, gifPropertiesPointer) == false {
			return delay
		}
		
		let gifProperties: CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)
		
		// Get delay time
		var delayObject: AnyObject = unsafeBitCast(
			CFDictionaryGetValue(gifProperties,
													 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
			to: AnyObject.self)
		if delayObject.doubleValue == 0 {
			delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
																											 Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
		}
		
		if let delayObject = delayObject as? Double, delayObject > 0 {
			delay = delayObject
		} else {
			delay = 0.1 // Make sure they're not too fast
		}
		
		return delay
	}
	
	internal class func gcdForPair(_ lhs: Int?, _ rhs: Int?) -> Int {
		var lhs = lhs
		var rhs = rhs
		// Check if one of them is nil
		if rhs == nil || lhs == nil {
			if rhs != nil {
				return rhs!
			} else if lhs != nil {
				return lhs!
			} else {
				return 0
			}
		}
		
		// Swap for modulo
		if lhs! < rhs! {
			let ctp = lhs
			lhs = rhs
			rhs = ctp
		}
		
		// Get greatest common divisor
		var rest: Int
		while true {
			rest = lhs! % rhs!
			
			if rest == 0 {
				return rhs! // Found it
			} else {
				lhs = rhs
				rhs = rest
			}
		}
	}
	
	internal class func gcdForArray(_ array: [Int]) -> Int {
		if array.isEmpty {
			return 1
		}
		
		var gcd = array[0]
		
		for val in array {
			gcd = UIImage.gcdForPair(val, gcd)
		}
		
		return gcd
	}
	
	internal class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
		let (frames, duration) = getFramesAndDuration(from: source)
		
		// Heyhey
		let animation = UIImage.animatedImage(with: frames,
																					duration: duration)
		return animation
	}
	
	fileprivate class func getFramesAndDuration(from source: CGImageSource) -> (frames: [UIImage], duration: Double) {
		let count = CGImageSourceGetCount(source)
		var images = [CGImage]()
		var delays = [Int]()
		
		// Fill arrays
		for index in 0..<count {
			// Add image
			if let image = CGImageSourceCreateImageAtIndex(source, index, nil) {
				images.append(image)
			}
			
			// At it's delay in cs
			let delaySeconds = UIImage.delayForImageAtIndex(Int(index),
																											source: source)
			delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
		}
		
		// Calculate full duration
		let duration: Int = {
			var sum = 0
			
			for val: Int in delays {
				sum += val
			}
			
			return sum
		}()
		
		// Get frames
		let gcd = gcdForArray(delays)
		var frames = [UIImage]()
		
		var frame: UIImage
		var frameCount: Int
		for index in 0..<count {
			frame = UIImage(cgImage: images[Int(index)])
			frameCount = Int(delays[Int(index)] / gcd)
			
			for _ in 0..<frameCount {
				frames.append(frame)
			}
		}
		return (frames: frames, duration: Double(duration) / 1000)
	}
	
}
