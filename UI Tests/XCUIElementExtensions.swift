//
//  XCUIElementExtensions.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/02/2026.
//
import XCTest

extension XCUIElement {
    public func conditionalTap(_ condition: Bool) {
        if condition {
            tap()
        }
    }
    
    public func conditionalSwipeUp(_ condition: Bool) {
        if condition {
            swipeUp()
        }
    }
}
