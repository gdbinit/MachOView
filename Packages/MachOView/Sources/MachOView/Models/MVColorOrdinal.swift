//
//  MVColorOrdinal.swift
//  
//
//  Created by d on 2023/06/08.
//

import Foundation
import AppKit

enum MVColorOrdinal: UInt8 {
    case black = 1
    case darkGray
    case lightGray
    case white
    case gray
    case red
    case green
    case blue
    case cyan
    case yellow
    case magenta
    case orange
    case purple
    case brown
  
    init?(color: NSColor) {
        if color == .black {
            self = MVColorOrdinal.black
        } else if color == .darkGray {
            self = MVColorOrdinal.darkGray
        } else if color == .lightGray {
            self = MVColorOrdinal.lightGray
        } else if color == .white {
            self = MVColorOrdinal.white
        } else if color == .gray {
            self = MVColorOrdinal.gray
        } else if color == .red {
            self = MVColorOrdinal.red
        } else if color == .green {
            self = MVColorOrdinal.green
        } else if color == .blue {
            self = MVColorOrdinal.blue
        } else if color == .cyan {
            self = MVColorOrdinal.cyan
        } else if color == .yellow {
            self = MVColorOrdinal.yellow
        } else if color == .magenta {
            self = MVColorOrdinal.magenta
        } else if color == .orange {
            self = MVColorOrdinal.orange
        } else if color == .purple {
            self = MVColorOrdinal.purple
        } else if color == .brown {
            self = MVColorOrdinal.brown
        }
    }
    
    var color: NSColor? {
        switch self {
        case .black:
            return .black
        case .darkGray:
            return .darkGray
        case .lightGray:
            return .lightGray
        case .white:
            return .white
        case .gray:
            return .gray
        case .red:
            return .red
        case .green:
            return .green
        case .blue:
            return .blue
        case .cyan:
            return .cyan
        case .yellow:
            return .yellow
        case .magenta:
            return .magenta
        case .orange:
            return .orange
        case .purple:
            return .purple
        case .brown:
            return .brown
        }
    }
}
