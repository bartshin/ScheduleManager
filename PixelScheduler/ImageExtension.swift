//
//  LabelExtension.swift
//  ScheduleManager
//
//  Created by Shin on 3/23/21.
//

import UIKit

extension UIImage {
    var toAttributeText: NSAttributedString
    {
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = self
        let ratio = attachment.image!.size.width / attachment.image!.size.height
        attachment.bounds = CGRect(x: attachment.bounds.origin.x, y: attachment.bounds.origin.y, width: ratio * CGFloat(40), height: CGFloat(40))
        let attachmentString:NSAttributedString = NSAttributedString(attachment: attachment)
        return attachmentString
    }
    func makeAttributedString(with text: String) -> NSMutableAttributedString {
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = self
        let ratio = attachment.image!.size.width / attachment.image!.size.height
        attachment.bounds = CGRect(x: attachment.bounds.origin.x, y: attachment.bounds.origin.y, width: ratio * CGFloat(15), height: CGFloat(15))
        let mutableString = NSMutableAttributedString(attachment: attachment)
        let attributeText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)])
        mutableString.append(attributeText)
        return mutableString
    }
}


