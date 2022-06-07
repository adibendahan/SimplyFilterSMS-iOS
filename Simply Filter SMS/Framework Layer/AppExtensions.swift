//
//  AppExtensions.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/01/2022.
//

import SwiftUI

extension EnvironmentValues {
    var isPreview: Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
        return false
#endif
    }
    
    var isDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
}

extension Color {
    static func listBackgroundColor(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .light {
            return Color(uiColor: UIColor.secondarySystemBackground)
        }
        else {
            return Color(uiColor: UIColor.systemBackground)
        }
    }
}

extension AnyTransition {
    static var opacitySlowInFastOut: AnyTransition {
        .asymmetric(
            insertion: .opacity.animation(.easeIn(duration: 0.35)),
            removal: .opacity.animation(.easeOut(duration: 0.15)).combined(with: .scale)
        )
    }
}

extension Date {
    func daysBetween(date: Date) -> Int {
        return Date.daysBetween(start: self, end: date)
    }
    
    func minutesBetween(date: Date) -> Int {
        return Date.minutesBetween(start: self, end: date)
    }
    
    static func daysBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        
        let date1 = calendar.startOfDay(for: start)
        let date2 = calendar.startOfDay(for: end)
        
        let a = calendar.dateComponents([.day], from: date1, to: date2)
        return a.value(for: .day)!
    }
    
    static func minutesBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        
        let date1 = calendar.startOfDay(for: start)
        let date2 = calendar.startOfDay(for: end)
        
        let a = calendar.dateComponents([.minute], from: date1, to: date2)
        return a.value(for: .minute)!
    }
}

extension FileManager {
    func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = self.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ conditional: Bool, @ViewBuilder _ content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
    
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}
