//
//  DebugDataManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 04/04/2026.
//

import Foundation

protocol DebugDataManagerProtocol: AnyObject {
    func load()
    func load(for langCode: String)
}
