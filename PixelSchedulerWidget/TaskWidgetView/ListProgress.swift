//
//  ListProgress.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/20/21.
//

import SwiftUI

struct ListProgress: View {
    
    private let size: CGSize
    private let progress: (Int, Int)
    private let coinImage = Image("coin").resizable()
    private let palette: UserConfig.ColorPalette
    private func drawCorner(startPoint: CGPoint, horizontalInvert: Bool, verticalInvert: Bool, edgeAdjust: CGFloat, path: inout Path) {
        let offsetHorizontal: CGFloat = horizontalInvert ? -edgeAdjust : edgeAdjust
        let offsetVertical: CGFloat = verticalInvert ? -edgeAdjust: edgeAdjust
        let isInverse = verticalInvert != horizontalInvert
        path.move(to: startPoint)
        path.addLine(to: CGPoint(x: isInverse ? startPoint.x: startPoint.x + offsetHorizontal,
                                 y: isInverse ? startPoint.y - offsetVertical: startPoint.y))
        path.addLine(to: CGPoint(x: startPoint.x + offsetHorizontal,
                                 y: startPoint.y - offsetVertical))
        path.addLine(to: CGPoint(x: startPoint.x + ( (isInverse ? 1: 2) * offsetHorizontal),
                                 y: startPoint.y - ( (isInverse ? 2: 1) * offsetVertical)))
        path.addLine(to: CGPoint(x: startPoint.x + (2 * offsetHorizontal),
                                 y: startPoint.y - (2 * offsetVertical)))
    }
    private func createContainer(in size: CGSize, edgeAdjust: CGFloat) -> Path {
        let leftTop = CGPoint(x: 0, y: 0)
        let rightTop = CGPoint(x: size.width, y: 0)
        let rightBottom = CGPoint(x: size.width, y: size.height)
        let leftBottom = CGPoint(x: 0, y: size.height)
        
        let path = Path { path in
            drawCorner(startPoint: CGPoint(x: leftTop.x,
                                           y: leftTop.y + (2 * edgeAdjust)),
                       horizontalInvert: false,
                       verticalInvert: false,
                       edgeAdjust: edgeAdjust, path: &path)
            path.addLine(to: CGPoint(x: rightTop.x - (2 * edgeAdjust),
                                     y: rightTop.y))
            drawCorner(startPoint: CGPoint(x: rightTop.x - (2 * edgeAdjust),
                                           y: rightTop.y),
                       horizontalInvert: false,
                       verticalInvert: true,
                       edgeAdjust: edgeAdjust, path: &path)
            path.addLine(to: CGPoint(x: rightBottom.x, y: rightBottom.y - (2 * edgeAdjust)))
            drawCorner(startPoint: CGPoint(x: rightBottom.x, y: rightBottom.y - (2 * edgeAdjust))
                       , horizontalInvert: true, verticalInvert: true, edgeAdjust: edgeAdjust, path: &path)
            path.addLine(to: CGPoint(x: leftBottom.x + (2 * edgeAdjust),
                                     y: leftBottom.y))
            drawCorner(startPoint: CGPoint(
                        x: leftBottom.x + (2 * edgeAdjust),
                        y: leftBottom.y),
                       horizontalInvert: true, verticalInvert: false, edgeAdjust: edgeAdjust, path: &path)
            path.addLine(to: CGPoint(x: leftTop.x,
                                     y: leftTop.y + (2 * edgeAdjust)))
            
        }
        return path
    }
    
    var body: some View {
        ZStack {
            HStack {
                if progress.1 > 0 {
                    ForEach(Range(0...(progress.1 - 1))) { index in
                        coinImage
                            .opacity(index < progress.0 ? 1: 0.3)
                    }
                }
            }
            .padding([.top, .bottom], 5 - CGFloat(progress.1))
            .padding([.leading, .trailing], 5)
            createContainer(in: CGSize(
                                width: size.width ,
                                height: size.height),
                            edgeAdjust: 5)
                .stroke(Color(palette.primary.withAlphaComponent(0.5)), lineWidth: 3)
                
        }
    }
    
    init(in size: CGSize, for progress: (Int, Int), palette: UserConfig.ColorPalette) {
        self.size = size
        if progress.1 > 5 {
            let completed = (Float(progress.0) / Float(progress.1))
            self.progress = (Int(round(completed * 5)), 5)
        }else {
            self.progress = progress
        }
        self.palette = palette
    }
}
