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


extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
