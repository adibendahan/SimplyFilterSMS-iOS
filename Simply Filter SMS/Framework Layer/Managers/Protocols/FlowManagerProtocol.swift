//
//  FlowManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation

protocol FlowManagerProtocol {
    func recordLaunch(_ screen: Screen) -> Bool
    func request(_ screen: Screen)
    func enableWhatsNew()
    func next() -> Screen?
    func complete(_ screen: Screen)
    func resetSession()
}
