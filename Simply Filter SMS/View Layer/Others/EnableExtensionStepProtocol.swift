//
//  EnableExtensionStepProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 25/03/2026.
//

import SwiftUI

protocol EnableExtensionStepProtocol {
    var stepNumber: Int { get }
    var title: String { get }
    var description: String { get }
    var symbolName: String? { get }
    var symbolColor: Color? { get }
    var showsAppIcon: Bool { get }
    var isToggle: Bool { get }
    var isLast: Bool { get }
}
