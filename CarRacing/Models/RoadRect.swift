//
//  RoadRect.swift
//  DriveFast
//
//  Created by Ly Truong H. VN.Danang on 09/05/2023.
//

import UIKit

// MARK: - RoadRect

struct RoadRect {
    var minY: CGFloat
    var minX: CGFloat
    var maxY: CGFloat
    var maxX: CGFloat
    
    var midX: CGFloat {
        return (maxX - minX) / 2
    }
}
