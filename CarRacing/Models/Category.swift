//
//  Category.swift
//  DriveFast
//
//  Created by Ly Truong H. VN.Danang on 09/05/2023.
//

import Foundation

// MARK: - Category

enum Category: UInt32 {
    case fuel = 0x1000
    case coin = 0x100
    case car = 0x10
    case player = 0x1
    case none = 0x10000
}

// MARK: - GameOverReason

enum GameOverReason {
    case runningOutOfFuel
    case crash
}
