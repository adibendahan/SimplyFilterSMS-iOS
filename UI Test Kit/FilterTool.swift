//
//  FilterTool.swift
//  UI Test Kit
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import Foundation

enum FilterTool {
    case testYourFilters
    case exportFilters
    case importFilters

    var symbol: String {
        switch self {
        case .testYourFilters:
            return "arrow.up.message"
        case .exportFilters:
            return "square.and.arrow.up"
        case .importFilters:
            return "square.and.arrow.down"
        }
    }
}
