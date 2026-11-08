//
//  mock_DefaultsManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 28/01/2022.
//

import Foundation
import SwiftUI
import XCTest
@testable import Simply_Filter_SMS

class mock_DefaultsManager: DefaultsManagerProtocol {

    var isAppFirstRunGetCounter = 0
    var isAppFirstRunSetCounter = 0
    var isAddFilterExpandedGetCounter = 0
    var isAddFilterExpandedSetCounter = 0
    var isFilterOptionsCollapsedGetCounter = 0
    var isFilterOptionsCollapsedSetCounter = 0
    var lastOfflineToastDismissGetCounter = 0
    var lastOfflineToastDismissSetCounter = 0
    var sessionStartDateGetCounter = 0
    var sessionStartDateSetCounter = 0
    var sessionCounterGetCounter = 0
    var sessionCounterSetCounter = 0
    var didPromptForReviewGetCounter = 0
    var didPromptForReviewSetCounter = 0
    var didTipGetCounter = 0
    var didTipSetCounter = 0
    var installDateGetCounter = 0
    var installDateSetCounter = 0
    var lastSeenWhatsNewVersionGetCounter = 0
    var lastSeenWhatsNewVersionSetCounter = 0
    var didDismissReportingExtensionNudgeGetCounter = 0
    var didDismissReportingExtensionNudgeSetCounter = 0

    var isAppFirstRunClosure: (() -> (Bool))?
    var isAddFilterExpandedClosure: (() -> (Bool))?
    var isFilterOptionsCollapsedClosure: (() -> (Bool))?
    var lastOfflineToastDismissClosure: (() -> (Date?))?
    var sessionStartDateClosure: (() -> (Date?))?
    var sessionCounterClosure: (() -> (Int))?
    var didPromptForReviewClosure: (() -> (Bool))?
    var didTipClosure: (() -> (Bool))?
    var installDateClosure: (() -> (Date))?
    var lastSeenWhatsNewVersionClosure: (() -> (Int))?
    var didDismissReportingExtensionNudgeClosure: (() -> (Bool))?

    var isAppFirstRun: Bool {
        get {
            self.isAppFirstRunGetCounter += 1
            return self.isAppFirstRunClosure?() ?? false
        }
        set {
            self.isAppFirstRunSetCounter += 1
        }
    }
    
    var isAddFilterExpanded: Bool {
        get {
            self.isAddFilterExpandedGetCounter += 1
            return self.isAddFilterExpandedClosure?() ?? false
        }
        set {
            self.isAddFilterExpandedSetCounter += 1
        }
    }

    var isFilterOptionsCollapsed: Bool {
        get {
            self.isFilterOptionsCollapsedGetCounter += 1
            return self.isFilterOptionsCollapsedClosure?() ?? false
        }
        set {
            self.isFilterOptionsCollapsedSetCounter += 1
        }
    }
    
    var lastOfflineToastDismiss: Date? {
        get {
            self.lastOfflineToastDismissGetCounter += 1
            return self.lastOfflineToastDismissClosure?() ?? Date()
        }
        set {
            self.lastOfflineToastDismissSetCounter += 1
        }
    }
    
    var sessionStartDate: Date? {
        get {
            self.sessionStartDateGetCounter += 1
            return self.sessionStartDateClosure?() ?? Date()
        }
        set {
            self.sessionStartDateSetCounter += 1
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

    var didTip: Bool {
        get {
            self.didTipGetCounter += 1
            return self.didTipClosure?() ?? false
        }
        set {
            self.didTipSetCounter += 1
        }
    }

    var installDate: Date {
        get {
            self.installDateGetCounter += 1
            return self.installDateClosure?() ?? Date()
        }
        set {
            self.installDateSetCounter += 1
        }
    }

    var lastSeenWhatsNewVersion: Int {
        get {
            self.lastSeenWhatsNewVersionGetCounter += 1
            return self.lastSeenWhatsNewVersionClosure?() ?? 0
        }
        set {
            self.lastSeenWhatsNewVersionSetCounter += 1
        }
    }

    var didDismissReportingExtensionNudge: Bool {
        get {
            self.didDismissReportingExtensionNudgeGetCounter += 1
            return self.didDismissReportingExtensionNudgeClosure?() ?? false
        }
        set {
            self.didDismissReportingExtensionNudgeSetCounter += 1
        }
    }

    var inactivityNotificationDeclineCount = 0
    var inactivityNotificationLastDeclineSession = 0
    var sessionNudgeLastShownSessions: [String: Int] = [:]
    var inactivityNotificationWasGranted = false

    var accentColorRGB: [String: Double] = kNoColorDict

    func resetCounters() {
        self.isAppFirstRunGetCounter = 0
        self.isAppFirstRunSetCounter = 0
        self.isAddFilterExpandedGetCounter = 0
        self.isAddFilterExpandedSetCounter = 0
        self.isFilterOptionsCollapsedGetCounter = 0
        self.isFilterOptionsCollapsedSetCounter = 0
    }
    
    func reset() { }
}
