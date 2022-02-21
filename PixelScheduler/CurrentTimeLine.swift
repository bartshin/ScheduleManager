//
//  DailyViewTimeLine.swift
//  PixelScheduler
//
//  Created by Shin on 2/28/21.
//

import SwiftUI

struct DailyViewTimeLine: View {
    private let width: CGFloat
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(
                        x: 0,
                        y: 2.5))
            path.addLine(to: CGPoint(
                            x: width, 
                            y: 2.5))
        }
        .stroke(Color.red, lineWidth: 2.5)
    }
    init(width: CGFloat) {
        self.width = width
    }
}
