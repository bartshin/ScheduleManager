//
//  TileView.swift
//  FancyScheduler
//
//  Created by Shin on 4/1/21.
//

import UIKit

class TileView: UIView {
    
    private let tile_center = UIImage(named: "tile_center")!
    private let tile_left = UIImage(named: "tile_left")!
    private let tile_right = UIImage(named: "tile_right")!

    override func draw(_ rect: CGRect) {
        
        // Variable
        let sideTileWidth: CGFloat = 15
        let centerTileWidth: CGFloat = bounds.width - (sideTileWidth * 2)
        let tileHeight = bounds.height
        let rightTileStartX = sideTileWidth + centerTileWidth
        
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw left tile
        let leftTilePath = UIBezierPath(
            rect: CGRect(x: 0, y: 0, width: sideTileWidth, height: tileHeight))
        context.saveGState()
        leftTilePath.addClip()
        context.translateBy(x: 0, y: 0)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -tile_left.size.height)
        context.draw(tile_left.cgImage!,
                     in: CGRect(x: 0, y: 0, width: tile_left.size.width, height: tile_left.size.height))
        context.restoreGState()

        // Draw center tile
        let centerTileRect = CGRect(
            x: sideTileWidth, y: 0, width: centerTileWidth, height: tileHeight)
        let centerTilePath = UIBezierPath(rect: centerTileRect)
        context.saveGState()
        centerTilePath.addClip()
        context.scaleBy(x: 1, y: -1)
        context.draw(tile_center.cgImage!, in: CGRect(x: centerTileRect.minX, y: -centerTileRect.minY, width: tile_center.size.width, height: tile_center.size.height), byTiling: true)
        context.restoreGState()
        
        // Draw right tile
        let rightTileRect = CGRect(x: rightTileStartX, y: 0, width: sideTileWidth, height: tileHeight)
        let rightTilePath = UIBezierPath(rect: rightTileRect)
        context.saveGState()
        rightTilePath.addClip()
        context.scaleBy(x: 1, y: -1)
        context.draw(tile_right.cgImage!, in: CGRect(x: rightTileRect.minX, y: -rightTileRect.minY, width: tile_right.size.width, height: tile_right.size.height))
        context.restoreGState()
    }

}
