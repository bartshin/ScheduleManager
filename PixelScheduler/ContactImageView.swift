//
//  ContactImageView.swift
//  PixelScheduler
//
//  Created by Shin on 4/12/21.
//

import SwiftUI

struct ContactImageView: View {
    
    private let name: String
    private let priority: Int
    private let profileImage: UIImage
    static let defaultIamge = UIImage(named: "default_profile")!
    var palette: SettingKey.ColorPalette
    
    var body: some View {
        Image(uiImage: profileImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(Circle())
            .overlay(Circle()
                        .stroke(Color.byPriority(priority),lineWidth: 5)
            )
    }
    init(name: String, priority: Int, image: UIImage? = nil, palette: SettingKey.ColorPalette) {
        self.name = name
        self.priority = priority
        self.profileImage = image ?? ContactImageView.defaultIamge
        self.palette = palette
    }
}

struct ContactImageView_Previews: PreviewProvider {
    static var previews: some View {
        ContactImageView(name: "김돌쇠", priority: 2, palette: .forest)
            .frame(width: 200,
                   height: 200)
    }
}
