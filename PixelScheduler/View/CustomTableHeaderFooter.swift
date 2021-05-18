//
//  CustomTableHeader.swift
//  ScheduleManager
//
//  Created by Shin on 3/24/21.
//

import UIKit

class CustomTableHeaderFooter: UITableViewHeaderFooterView {
   
    var title: UILabel?
    var image: UIImageView?
    var button: UIButton?
    
    init(for reuseID: ReuseID, title: String? = nil, image: UIImage? = nil) {
        if title != nil {
            self.title = UILabel()
            self.title!.text = title
        }else {
            self.title = nil
        }
        if image != nil {
            self.image = UIImageView(image: image!)
        }else {
            self.image = nil
        }
        self.button = nil
        super.init(reuseIdentifier: reuseID.rawValue)
        configureContents()
    }
    init(for reuseID: ReuseID, onlyFor button: UIButton) {
        self.button = button
        self.title = nil
        self.image = nil
        super.init(reuseIdentifier: reuseID.rawValue)
        configureContents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureContents() {
        if let button = button {
            button.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(button)
            NSLayoutConstraint.activate(
                [
                    button.heightAnchor.constraint(equalToConstant: 30),
                    button.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20)            ]
            )
        }else {
            title?.translatesAutoresizingMaskIntoConstraints = false
            if let image = image, let title = title {
                image.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(image)
                contentView.addSubview(title)
                
                // Center the image vertically and place it near the leading
                // edge of the view. Constrain its width and height to 50 points.
                NSLayoutConstraint.activate([
                    image.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                    image.widthAnchor.constraint(equalToConstant: 20),
                    image.heightAnchor.constraint(equalToConstant: 20),
                    image.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    
                    // Center the label vertically, and use it to fill the remaining
                    // space in the header view.
                    title.heightAnchor.constraint(equalToConstant: 30),
                    title.leadingAnchor.constraint(equalTo: image.trailingAnchor,
                                                   constant: 8),
                    title.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
                ])
            }else if let title = title , image == nil {
                contentView.addSubview(title)
                NSLayoutConstraint.activate([
                    title.heightAnchor.constraint(equalToConstant: 30),
                    title.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    title.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
                ])
            }
        }
    }
    
    enum ReuseID: String {
        case CustomFooter
        case CustomHeader
    }
}
