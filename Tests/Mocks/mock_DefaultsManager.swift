//
//  mock_DefaultsManager.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 28/01/2022.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class mock_DefaultsManager: DefaultsManagerProtocol {
    
    var isAppFirstRunGetCounter = 0
    var isAppFirstRunSetCounter = 0
    var isExpandedAddFilterGetCounter = 0
    var isExpandedAddFilterSetCounter = 0
    
    var isAppFirstRunClosure: (() -> (Bool))?
    var isExpandedAddFilterClosure: (() -> (Bool))?
    
    var isAppFirstRun: Bool {
        get {
            self.isAppFirstRunGetCounter += 1
            return self.isAppFirstRunClosure?() ?? false
        }
        set {
            self.isAppFirstRunSetCounter += 1
        }
    }
    
    var isExpandedAddFilter: Bool {
        get {
            self.isExpandedAddFilterGetCounter += 1
            return self.isExpandedAddFilterClosure?() ?? false
        }
        set {
            self.isExpandedAddFilterSetCounter += 1
        }
    }
    
    func resetCounters() {
        self.isAppFirstRunGetCounter = 0
        self.isAppFirstRunSetCounter = 0
        self.isExpandedAddFilterGetCounter = 0
        self.isExpandedAddFilterSetCounter = 0
    }
}
