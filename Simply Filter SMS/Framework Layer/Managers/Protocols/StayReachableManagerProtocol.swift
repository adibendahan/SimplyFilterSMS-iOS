//
//  StayReachableManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 24/11/2026.
//

import Foundation

protocol StayReachableManagerProtocol: AnyObject {
    func rememberedSections(in filters: [Filter]) -> [StayReachableSection]
    func isAlreadyAllowed(_ text: String, excluding ownFilter: Filter?, in filters: [Filter]) -> Bool
    func save(_ sections: [StayReachableSection])
}


//MARK: - Sections -
struct StayReachableSection: Identifiable {
    let id = UUID()
    var language: Locale.LanguageCode
    var firstName = ""
    var surname = ""
    var street = ""
    var restoredFilters: [StayReachableField: Filter] = [:]

    var texts: [String] {
        return StayReachableField.allCases.map { self[keyPath: $0.keyPath] }
    }

    var isBlank: Bool {
        return self.texts.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func trimmedText(_ field: StayReachableField) -> String {
        return self[keyPath: field.keyPath].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isRestored(_ field: StayReachableField) -> Bool {
        guard let filter = self.restoredFilters[field] else { return false }
        let filterText = (filter.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return self.trimmedText(field) == filterText
    }
}

enum StayReachableField: String, CaseIterable {
    case firstName, surname, street

    var keyPath: WritableKeyPath<StayReachableSection, String> {
        switch self {
        case .firstName: return \.firstName
        case .surname: return \.surname
        case .street: return \.street
        }
    }
}
