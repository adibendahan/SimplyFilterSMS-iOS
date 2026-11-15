//
//  TestLists.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import Foundation

enum TestLists {
    static let curatedPromotions = "UI Test Promotions"
    static let subscriptionName = "UI Test Subscription"
    static let subscriptionURL = Self.url(of: "subscribe.sfsfilters")
    static let notAFilterListURL = Self.url(of: "invalid.sfsfilters")

    private static func url(of fileName: String) -> String {
        return "https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/ui-tests/\(fileName)"
    }
}
