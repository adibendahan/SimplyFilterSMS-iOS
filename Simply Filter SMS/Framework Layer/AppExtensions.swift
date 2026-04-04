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
#endif // DEBUG
    }
    
    var isDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif // DEBUG
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

extension String {
    var highlightedAsRegex: AttributedString {
        let nsAttr = NSMutableAttributedString(string: self)
        let nsLen = (self as NSString).length
        let fullRange = NSRange(location: 0, length: nsLen)

        let rules: [(String, UIColor)] = [
            (#"\^|\$"#,                         .systemGreen),    // anchors
            (#"\|"#,                             .secondaryLabel), // alternation
            (#"[*+?]|\{[0-9,]*\}"#,             .systemOrange),   // quantifiers
            (#"[()]"#,                           .systemPurple),   // groups
            (#"\[(?:[^\]\\]|\\.)*\]"#,           .systemBlue),     // character classes
            (#"\\."#,                            .systemTeal),     // escape sequences
        ]

        for (pat, color) in rules {
            guard let re = try? NSRegularExpression(pattern: pat) else { continue }
            for match in re.matches(in: self, range: fullRange) {
                nsAttr.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }

        return (try? AttributedString(nsAttr, including: \.uiKit)) ?? AttributedString(self)
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

extension View {
    @ViewBuilder func sidebarNavigationRow(screen: Screen, isRegular: Bool, onTap: @escaping () -> Void) -> some View {
        if isRegular {
            self.contentShape(Rectangle())
                .highPriorityGesture(TapGesture().onEnded { _ in onTap() })
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
        } else {
            NavigationLink(value: screen) { self }
        }
    }
}

extension View {
    @ViewBuilder func phoneOnlyStackNavigationView() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.navigationViewStyle(.stack)

        } else {
            self
        }
    }
}
