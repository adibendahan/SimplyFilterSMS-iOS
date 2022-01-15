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
