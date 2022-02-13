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
    var lastOfflineNotificationDismissGetCounter = 0
    var lastOfflineNotificationDismissSetCounter = 0
    var sessionCounterGetCounter = 0
    var sessionCounterSetCounter = 0
    var didPromptForReviewGetCounter = 0
    var didPromptForReviewSetCounter = 0
    var appAgeGetCounter = 0
    var appAgeSetCounter = 0
    
    var isAppFirstRunClosure: (() -> (Bool))?
    var isExpandedAddFilterClosure: (() -> (Bool))?
    var lastOfflineNotificationDismissClosure: (() -> (Date?))?
    var sessionCounterClosure: (() -> (Int))?
    var didPromptForReviewClosure: (() -> (Bool))?
    var appAgeClosure: (() -> (Date))?
    
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
    
    var lastOfflineNotificationDismiss: Date? {
        get {
            self.lastOfflineNotificationDismissGetCounter += 1
            return self.lastOfflineNotificationDismissClosure?() ?? Date()
        }
        set {
            self.lastOfflineNotificationDismissSetCounter += 1
        }
    }
    
    var sessionCounter: Int {
        get {
            self.sessionCounterGetCounter += 1
            return self.sessionCounterClosure?() ?? 0
        }
        set {
            self.sessionCounterSetCounter += 1
        }
    }
    
    var didPromptForReview: Bool {
        get {
            self.didPromptForReviewGetCounter += 1
            return self.didPromptForReviewClosure?() ?? false
        }
        set {
            self.didPromptForReviewSetCounter += 1
        }
    }
    
    var appAge: Date {
        get {
            self.appAgeGetCounter += 1
            return self.appAgeClosure?() ?? Date()
        }
        set {
            self.appAgeSetCounter += 1
        }
    }
    
    func resetCounters() {
        self.isAppFirstRunGetCounter = 0
        self.isAppFirstRunSetCounter = 0
        self.isExpandedAddFilterGetCounter = 0
        self.isExpandedAddFilterSetCounter = 0
    }
}
