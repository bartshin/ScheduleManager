//
//  PuzzleProgress.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/20/21.
//

import SwiftUI
import WidgetKit

struct PuzzleProgress: View {
    
    private let progress: (Int, Int)
    private let palette: UserConfig.ColorPalette
    
    private func getPoint(from origin: CGPoint, length: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: origin.x + length * CGFloat(cos(angle.radians)),
            y: origin.y + length * CGFloat(sin(angle.radians)))
    }
    
    private func addJigSawDecoration(isFirst: Bool, at point: CGPoint, baseAngle: Angle, radius: CGFloat, path: inout Path) {
        
        let beforeMid = getPoint(from: point,
                                       length: radius / 20,
                                       angle: Angle(degrees: isFirst ? baseAngle.degrees + 180: baseAngle.degrees))
        let afterMid = getPoint(from: point,
                                       length: radius / 20,
                                       angle: Angle(degrees: isFirst ? baseAngle.degrees: baseAngle.degrees + 180))
        path.addLine(to: beforeMid)
        let outsidePoint = getPoint(from: point,
                                         length: radius / 8,
                                         angle: Angle(degrees: baseAngle.degrees + 90))
        let startAngle = Angle(degrees: baseAngle.degrees + 240)
        let endAngle = Angle(degrees: baseAngle.degrees - 60)
        
        path.addArc(
            center: outsidePoint,
            radius: radius / 10,
            startAngle: isFirst ? startAngle: endAngle,
            endAngle: isFirst ? endAngle: startAngle,
            clockwise: isFirst, transform: .identity)
        
       
        path.addLine(to: afterMid)
    }
    
    func createFanShape(at center: CGPoint, radius: CGFloat, startAngle: Angle, endAngle: Angle) -> Path {
        return Path { path in
            path.move(to: center)
            let firstEndPoint = getPoint(from: center, length: radius, angle: startAngle)
            addJigSawDecoration(isFirst: true, at: getPoint(
                                    from: center,
                                    length: radius * 0.7,
                                    angle: startAngle),
                                baseAngle: startAngle,
                                radius: radius,
                                path: &path)
            path.addLine(to: firstEndPoint)
            
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true, transform: .identity)
            
            addJigSawDecoration(isFirst: false, at:  getPoint(
                                    from: center,
                                    length: radius * 0.7,
                                    angle: endAngle),
                                baseAngle: endAngle,
                                radius: radius,
                                path: &path)
            path.addLine(to: center)
        }
    }
    
    
    var body: some View {
        GeometryReader { geometryProxy in
            let puzzleCenter = CGPoint(x: geometryProxy.size.width / 2,
                                       y: geometryProxy.size.height / 2)
            Group {
                
                let puzzleRadius: CGFloat = min(geometryProxy.size.height, geometryProxy.size.width) * 0.4
                let innerCircleRadius: CGFloat = puzzleRadius * 0.7
                
                let angleOfPiece: Double = 360 / Double(progress.1)
                let marginAngle = Double(11 - progress.1)
                ForEach(Range(1...progress.1)) { index in
                    
                    createFanShape(at: puzzleCenter,
                                   radius: puzzleRadius,
                                   startAngle:
                                    Angle(degrees:
                                            -Double(index) * angleOfPiece - marginAngle),
                                   endAngle:
                                    Angle(degrees: -Double(index + 1) * angleOfPiece + marginAngle
                                    ))
                        .fill(Color(palette.primary.withAlphaComponent(progress.0 < index ? 0.3: 1)))
                    
                }
                Circle()
                    .size(width: innerCircleRadius, height: innerCircleRadius)
                    .fill(Color(palette.quaternary))
                    .frame(width: innerCircleRadius, height: innerCircleRadius)
                    .position(x: puzzleCenter.x,
                              y: puzzleCenter.y)
                
                    
            }
            .frame(width: geometryProxy.size.width,
                   height: geometryProxy.size.height)
        }
        .background(Color(palette.quaternary))
    }
    
    init(progress: (Int, Int), palette: UserConfig.ColorPalette) {
        self.palette = palette
        if progress.1 > 10 {
            let completed = Float(progress.0) / Float(progress.1) * 10
            self.progress = (Int(round(completed)), 5)
        }else {
            self.progress = progress
        }
    }
}

struct PuzzleProgress_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleProgress(progress: (0, 1), palette: .basic)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
