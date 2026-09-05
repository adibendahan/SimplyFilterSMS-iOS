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
    var isExpandedAddFilterGetCounter = 0
    var isExpandedAddFilterSetCounter = 0
    var isFilterOptionsCollapsedGetCounter = 0
    var isFilterOptionsCollapsedSetCounter = 0
    var lastOfflineNotificationDismissGetCounter = 0
    var lastOfflineNotificationDismissSetCounter = 0
    var sessionAgeGetCounter = 0
    var sessionAgeSetCounter = 0
    var sessionCounterGetCounter = 0
    var sessionCounterSetCounter = 0
    var didPromptForReviewGetCounter = 0
    var didPromptForReviewSetCounter = 0
    var didTipGetCounter = 0
    var didTipSetCounter = 0
    var appAgeGetCounter = 0
    var appAgeSetCounter = 0
    var lastSeenWhatsNewVersionGetCounter = 0
    var lastSeenWhatsNewVersionSetCounter = 0
    var didDismissReportingExtensionNudgeGetCounter = 0
    var didDismissReportingExtensionNudgeSetCounter = 0
    var automaticFiltersNotificationExplainerAskCountGetCounter = 0
    var automaticFiltersNotificationExplainerAskCountSetCounter = 0
    var automaticFiltersNotificationExplainerLastDeclinedSessionGetCounter = 0
    var automaticFiltersNotificationExplainerLastDeclinedSessionSetCounter = 0
    var automaticFiltersNotificationPermissionWasGrantedGetCounter = 0
    var automaticFiltersNotificationPermissionWasGrantedSetCounter = 0

    var isAppFirstRunClosure: (() -> (Bool))?
    var isExpandedAddFilterClosure: (() -> (Bool))?
    var isFilterOptionsCollapsedClosure: (() -> (Bool))?
    var lastOfflineNotificationDismissClosure: (() -> (Date?))?
    var sessionAgeClosure: (() -> (Date?))?
    var sessionCounterClosure: (() -> (Int))?
    var didPromptForReviewClosure: (() -> (Bool))?
    var didTipClosure: (() -> (Bool))?
    var appAgeClosure: (() -> (Date))?
    var lastSeenWhatsNewVersionClosure: (() -> (Int))?
    var didDismissReportingExtensionNudgeClosure: (() -> (Bool))?
    private var sessionCounterValue = 0
    private var automaticFiltersNotificationExplainerAskCountValue = 0
    private var automaticFiltersNotificationExplainerLastDeclinedSessionValue = 0
    private var automaticFiltersNotificationPermissionWasGrantedValue = false

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

    var isFilterOptionsCollapsed: Bool {
        get {
            self.isFilterOptionsCollapsedGetCounter += 1
            return self.isFilterOptionsCollapsedClosure?() ?? false
        }
        set {
            self.isFilterOptionsCollapsedSetCounter += 1
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
    
    var sessionAge: Date? {
        get {
            self.sessionAgeGetCounter += 1
            return self.sessionAgeClosure?() ?? Date()
        }
        set {
            self.sessionAgeSetCounter += 1
        }
    }
    
    var sessionCounter: Int {
        get {
            self.sessionCounterGetCounter += 1
            return self.sessionCounterClosure?() ?? self.sessionCounterValue
        }
        set {
            self.sessionCounterSetCounter += 1
            self.sessionCounterValue = newValue
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

    var appAge: Date {
        get {
            self.appAgeGetCounter += 1
            return self.appAgeClosure?() ?? Date()
        }
        set {
            self.appAgeSetCounter += 1
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

    var automaticFiltersNotificationExplainerAskCount: Int {
        get {
            self.automaticFiltersNotificationExplainerAskCountGetCounter += 1
            return self.automaticFiltersNotificationExplainerAskCountValue
        }
        set {
            self.automaticFiltersNotificationExplainerAskCountSetCounter += 1
            self.automaticFiltersNotificationExplainerAskCountValue = newValue
        }
    }

    var automaticFiltersNotificationExplainerLastDeclinedSession: Int {
        get {
            self.automaticFiltersNotificationExplainerLastDeclinedSessionGetCounter += 1
            return self.automaticFiltersNotificationExplainerLastDeclinedSessionValue
        }
        set {
            self.automaticFiltersNotificationExplainerLastDeclinedSessionSetCounter += 1
            self.automaticFiltersNotificationExplainerLastDeclinedSessionValue = newValue
        }
    }

    var automaticFiltersNotificationPermissionWasGranted: Bool {
        get {
            self.automaticFiltersNotificationPermissionWasGrantedGetCounter += 1
            return self.automaticFiltersNotificationPermissionWasGrantedValue
        }
        set {
            self.automaticFiltersNotificationPermissionWasGrantedSetCounter += 1
            self.automaticFiltersNotificationPermissionWasGrantedValue = newValue
        }
    }

    var accentColorRGB: [String: Double] = kNoColorDict

    func resetCounters() {
        self.isAppFirstRunGetCounter = 0
        self.isAppFirstRunSetCounter = 0
        self.isExpandedAddFilterGetCounter = 0
        self.isExpandedAddFilterSetCounter = 0
        self.isFilterOptionsCollapsedGetCounter = 0
        self.isFilterOptionsCollapsedSetCounter = 0
        self.automaticFiltersNotificationExplainerAskCountGetCounter = 0
        self.automaticFiltersNotificationExplainerAskCountSetCounter = 0
        self.automaticFiltersNotificationExplainerLastDeclinedSessionGetCounter = 0
        self.automaticFiltersNotificationExplainerLastDeclinedSessionSetCounter = 0
        self.automaticFiltersNotificationPermissionWasGrantedGetCounter = 0
        self.automaticFiltersNotificationPermissionWasGrantedSetCounter = 0
    }
    
    func reset() { }
}
