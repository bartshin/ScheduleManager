//
//  NewLineTextView.swift
//  Schedule_B
//
//  Created by Shin on 3/1/21.
//

import UIKit

class placeHolderTextView: UITextView, UITextViewDelegate{
    
    private(set) var isEditing = false
    func textViewDidBeginEditing(_ textView: UITextView) {
        toggleDefault()
        isEditing = true
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        toggleDefault()
        isEditing = false
    }
    
    static let defaultDescription = "내용을 입력해주세요"
    private func toggleDefault() {
        if self.text == placeHolderTextView.defaultDescription {
            self.text = ""
        }else if self.text.isEmpty {
            self.text = placeHolderTextView.defaultDescription
        }
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.delegate = self
        self.textContainerInset = UIEdgeInsets(
            top: 20, left: 30, bottom: 20, right: 20)
        layer.cornerRadius = 10
        layer.borderWidth = 3
        layer.borderColor = CGColor(gray: 0.5, alpha: 1)
    }
}
