//
//  Car.swift
//  DriveFast
//
//  Created by Ly Truong H. VN.Danang on 09/05/2023.
//

import UIKit

// MARK: - Car

struct Car: Hashable {
    
    static var scaleRatio: CGFloat {
        UIDevice.current.isPad ? 6 : 4
    }
    
    private var _index: Int
    
    var index: Int { _index }
    var imageName: String { "car\(index)" }
    
    var ratio: CGFloat {
        var value = index > 4 ? Car.scaleRatio + 3 : Car.scaleRatio + 2
        if index == 20 { // truck
            value -= 2
        }
        return UIDevice.current.isPad ? value + 3 : value
    }
    
    init(index: Int) {
        self._index = index
    }
}

// MARK: - Equatable

extension Car: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs._index == rhs._index
    }
}
