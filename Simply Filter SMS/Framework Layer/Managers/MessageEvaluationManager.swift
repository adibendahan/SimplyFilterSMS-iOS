//
//  ExtensionManager.swift
//  Simply Filter SMS Extension
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import Foundation
import CoreData
import IdentityLookup
import NaturalLanguage
import OSLog

class MessageEvaluationManager: MessageEvaluationManagerProtocol {

    //MARK: - Initialization -

    /// Initializer for use in Extension/Tests context *creates a new container*
    /// - Parameter container: NSPersistentCloudKitContainer
    init(inMemory: Bool = false) {
        let isReadOnly = inMemory ? false : true
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory, isReadOnly: isReadOnly)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        self.persistentContainer = container
        self.context = container.viewContext
        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                self?.logger?.error("ERROR! While initializing MessageEvaluationManager: \(error), \(error.userInfo)")
            }
        })
    }

    /// Initializer for use in application context
    /// - Parameter container: NSPersistentCloudKitContainer
    init(container: NSPersistentCloudKitContainer) {
        self.persistentContainer = container
        self.context = container.viewContext
    }

    //MARK: - Public API (MessageEvaluationManagerProtocol) -

    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult {
        logger?.debug("━━━━ Evaluating message | sender: '\(sender, privacy: .public)' | body: '\(body, privacy: .public)' ━━━━")
        var result = MessageEvaluationResult(action: .none)
        defer {
            logger?.debug("━━━━ Final decision: action=\(result.action.logName, privacy: .public), reason='\(result.reason ?? "", privacy: .public)' ━━━━")
        }
        // Priority #1 - allUnknown (absolute gate, overrides everything)
        result = self.runAllUnknownRule()
        guard !result.action.isFiltered else {
            logger?.debug("Priority #1 (allUnknown) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #1 (allUnknown) → not active, continuing")
        // Priority #2 - Allow Filters
        result = self.runUserFilters(type: .allow, body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #2 (Allow Filters) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #2 (Allow Filters) → no match, continuing")
        // Priority #3 - Automatic Filters (allow)
        result = self.runAutomaticFiltersAllow(body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #3 (Automatic Filters Allow) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #3 (Automatic Filters Allow) → no match, continuing")
        // Priority #4 - Filter Rules
        result = self.runFilterRules(body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #4 (Filter Rules) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #4 (Filter Rules) → no match, continuing")
        // Priority #5 - Deny Filters
        result = self.runUserFilters(type: .deny, body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #5 (Deny Filters) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #5 (Deny Filters) → no match, continuing")
        // Priority #6 - Deny Language Filters
        result = self.runUserFilters(type: .denyLanguage, body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #6 (Deny Language Filters) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #6 (Deny Language Filters) → no match, continuing")
        // Priority #7 - Automatic Filters (deny)
        result = self.runAutomaticFiltersDeny(body: body, sender: sender)
        if !result.action.isFiltered {
            result = MessageEvaluationResult(action: .allow, reason: nil)
            logger?.debug("Priority #7 (Automatic Filters Deny) → no match → fallthrough ALLOW")
        }
        else {
            logger?.debug("Priority #7 (Automatic Filters Deny) → DECISION: \(result.action.logName, privacy: .public)")
        }
        return result
    }

    func setLogger(_ logger: Logger) {
        self.logger = logger
    }

    //MARK: - Private -

    private var logger: Logger?
    private var persistentContainer: NSPersistentContainer?
    private(set) var context: NSManagedObjectContext

    private func runAllUnknownRule() -> MessageEvaluationResult {
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "ruleId == %ld AND isActive == %@",
                                            RuleType.allUnknown.rawValue,
                                            NSNumber(value: true))
        guard (try? self.context.fetch(ruleRequest))?.isEmpty == false else {
            return MessageEvaluationResult(action: .none)
        }
        logger?.debug("[allUnknown] rule is active")
        return MessageEvaluationResult(action: .junk, reason: "testFilters_resultReason_unknownSender"~)
    }

    private func runUserFilters(type: FilterType, body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld", type.rawValue)
        guard let filters = try? self.context.fetch(fetchRequest) else {
            self.logger?.error("ERROR! While loading filters on MessageEvaluationManager.runUserFilters")
            return result
        }
        logger?.debug("[\(type.logDescription, privacy: .public)] Loaded \(filters.count, privacy: .public) filter(s)")
        switch type {
        case .allow:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let matched = self.isMataching(filter: filter, body: body, sender: sender)
                logger?.debug("  Checking allow filter '\(filter.text ?? "?", privacy: .public)' [target: \(filter.filterTarget.logDescription, privacy: .public), matching: \(filter.filterMatching.logDescription, privacy: .public), case: \(filter.filterCase.logDescription, privacy: .public)] → \(matched ? "MATCH" : "no match", privacy: .public)")
                guard matched else { continue }
                result = MessageEvaluationResult(action: .allow, reason: filter.text)
                logger?.debug("  → Returning ALLOW")
                break
            }
        case .deny:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let matched = self.isMataching(filter: filter, body: body, sender: sender)
                logger?.debug("  Checking deny filter '\(filter.text ?? "?", privacy: .public)' [target: \(filter.filterTarget.logDescription, privacy: .public), matching: \(filter.filterMatching.logDescription, privacy: .public), case: \(filter.filterCase.logDescription, privacy: .public), folder: \(filter.denyFolderType.logDescription, privacy: .public)] → \(matched ? "MATCH" : "no match", privacy: .public)")
                guard matched else { continue }
                result = MessageEvaluationResult(action: filter.denyFolderType.action, reason: filter.text)
                logger?.debug("  → Returning \(result.action.logName, privacy: .public) (folder: \(filter.denyFolderType.logDescription, privacy: .public))")
                break
            }
        case .denyLanguage:
            let detectedLanguage = NLLanguage.dominantLanguage(for: body)
            logger?.debug("  Detected message language: '\(detectedLanguage?.rawValue ?? "undetermined", privacy: .public)'")
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let language = NLLanguage(filterText: filter.text ?? "")
                let matched = language != .undetermined && detectedLanguage == language
                logger?.debug("  Checking language filter '\(language.localizedName ?? language.rawValue, privacy: .public)' → \(matched ? "MATCH" : "no match", privacy: .public)")
                guard matched else { continue }
                result = MessageEvaluationResult(action: filter.denyFolderType.action, reason: language.localizedName)
                logger?.debug("  → Returning \(result.action.logName, privacy: .public) for language '\(language.localizedName ?? language.rawValue, privacy: .public)'")
                break
            }
        }
        return result
    }

    private func loadAutomaticFilterCache() -> ([AutomaticFiltersLanguage], AutomaticFilterListsResponse)? {
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        let cacheRequest: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        guard let languageRecords = try? self.context.fetch(languageRequest),
              let cacheRow = try? self.context.fetch(cacheRequest).first,
              let filtersData = cacheRow.filtersData,
              let filterList = AutomaticFilterListsResponse(base64String: filtersData) else {
            return nil
        }
        return (languageRecords, filterList)
    }

    private func runAutomaticFiltersAllow(body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let lowercasedBody = body.lowercased()
        let lowercasedSender = sender.lowercased()
        guard let (languageRecords, filterList) = self.loadAutomaticFilterCache() else {
            logger?.debug("[Automatic Filters Allow] no cache, skipping")
            return result
        }
        logger?.debug("[Automatic Filters Allow] \(languageRecords.count, privacy: .public) language record(s)")
        for record in languageRecords {
            guard result.action == .none,
                  record.isActive,
                  let langRawValue = record.lang,
                  let languageResponse = filterList.filterLists[langRawValue] else { continue }
            let lang = NLLanguage(rawValue: langRawValue)
            for allowedSender in languageResponse.allowSenders {
                if lowercasedSender == allowedSender.lowercased() {
                    result = MessageEvaluationResult(action: .allow, reason: "Automatic Filters (\(lang.localizedName ?? langRawValue))")
                    logger?.debug("  → ALLOW: matched allow sender '\(allowedSender, privacy: .public)' [\(lang.localizedName ?? langRawValue, privacy: .public)]")
                    break
                }
            }
            guard !result.action.isFiltered else { break }
            for allowedBody in languageResponse.allowBody {
                if lowercasedBody.contains(allowedBody.lowercased()) {
                    result = MessageEvaluationResult(action: .allow, reason: "Automatic Filters (\(lang.localizedName ?? langRawValue))")
                    logger?.debug("  → ALLOW: matched allow body phrase '\(allowedBody, privacy: .public)' [\(lang.localizedName ?? langRawValue, privacy: .public)]")
                    break
                }
            }
        }
        return result
    }

    private func runAutomaticFiltersDeny(body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let lowercasedBody = body.lowercased()
        let lowercasedSender = sender.lowercased()
        guard let (languageRecords, filterList) = self.loadAutomaticFilterCache() else {
            logger?.debug("[Automatic Filters Deny] no cache, skipping")
            return result
        }
        logger?.debug("[Automatic Filters Deny] \(languageRecords.count, privacy: .public) language record(s)")
        for record in languageRecords {
            guard result.action == .none,
                  record.isActive,
                  let langRawValue = record.lang,
                  let languageResponse = filterList.filterLists[langRawValue] else { continue }
            let lang = NLLanguage(rawValue: langRawValue)
            logger?.debug("  Checking language '\(lang.localizedName ?? langRawValue, privacy: .public)' — denySenders: \(languageResponse.denySender.count, privacy: .public), denyBody: \(languageResponse.denyBody.count, privacy: .public)")
            for deniedSender in languageResponse.denySender {
                if lowercasedSender == deniedSender.lowercased() {
                    result = MessageEvaluationResult(action: .junk, reason: "Automatic Filters (\(lang.localizedName ?? langRawValue))")
                    logger?.debug("  → JUNK: matched deny sender '\(deniedSender, privacy: .public)' [\(lang.localizedName ?? langRawValue, privacy: .public)]")
                    break
                }
            }
            guard !result.action.isFiltered else { break }
            for deniedBody in languageResponse.denyBody {
                if lowercasedBody.contains(deniedBody.lowercased()) {
                    result = MessageEvaluationResult(action: .junk, reason: "Automatic Filters (\(lang.localizedName ?? langRawValue))")
                    logger?.debug("  → JUNK: matched deny body phrase '\(deniedBody, privacy: .public)' [\(lang.localizedName ?? langRawValue, privacy: .public)]")
                    break
                }
            }
        }
        return result
    }

    private func runFilterRules(body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        guard let activeRules = try? self.context.fetch(ruleRequest) else {
            self.logger?.error("ERROR! While loading rules on MessageEvaluationManager.runFilterRules")
            return result
        }
        logger?.debug("[Filter Rules] \(activeRules.count, privacy: .public) active rule(s)")
        for activeRule in activeRules {
            guard let ruleType = activeRule.ruleType else { continue }
            logger?.debug("  Checking rule: \(ruleType.logDescription, privacy: .public)")
            switch ruleType {
            case .allUnknown:
                break
            case .links:
                if body.containsLink {
                    result = MessageEvaluationResult(action: .junk, reason: ruleType.shortTitle)
                    logger?.debug("  → JUNK: links — body contains a link")
                }
                else {
                    logger?.debug("  → no link detected in body")
                }
            case .numbersOnly:
                if sender.rangeOfCharacter(from: .letters) != nil {
                    result = MessageEvaluationResult(action: .junk, reason: ruleType.shortTitle)
                    logger?.debug("  → JUNK: numbersOnly — sender '\(sender, privacy: .public)' triggered rule")
                }
                else {
                    logger?.debug("  → sender '\(sender, privacy: .public)' did not trigger numbersOnly rule")
                }
            case .shortSender:
                if sender.count <= Int(activeRule.selectedChoice) {
                    result = MessageEvaluationResult(action: .junk, reason: ruleType.shortTitle)
                    logger?.debug("  → JUNK: shortSender — sender length \(sender.count, privacy: .public) ≤ threshold \(Int(activeRule.selectedChoice), privacy: .public)")
                }
                else {
                    logger?.debug("  → sender length \(sender.count, privacy: .public) > threshold \(Int(activeRule.selectedChoice), privacy: .public), not short")
                }
            case .email:
                if sender.containsEmail {
                    result = MessageEvaluationResult(action: .junk, reason: ruleType.shortTitle)
                    logger?.debug("  → JUNK: email — sender '\(sender, privacy: .public)' looks like an email address")
                }
                else {
                    logger?.debug("  → sender '\(sender, privacy: .public)' is not an email address")
                }
            case .emojis:
                if body.containsEmoji {
                    result = MessageEvaluationResult(action: .junk, reason: ruleType.shortTitle)
                    logger?.debug("  → JUNK: emojis — body contains emoji(s)")
                }
                else {
                    logger?.debug("  → body contains no emojis")
                }
            case .countryAllowlist:
                guard let json = activeRule.selectedCountries,
                      let data = json.data(using: .utf8),
                      let allowedCodes = try? JSONDecoder().decode([String].self, from: data),
                      !allowedCodes.isEmpty else {
                    logger?.debug("  → countryAllowlist: no allowed codes configured, skipping")
                    break
                }
                guard let entry = CallingCodes.callingCode(for: sender) else {
                    logger?.debug("  → countryAllowlist: could not determine country for sender '\(sender, privacy: .public)', skipping")
                    break
                }
                if !allowedCodes.contains(entry.callingCode) {
                    result = MessageEvaluationResult(action: .junk, reason: ruleType.shortTitle)
                    logger?.debug("  → JUNK: countryAllowlist — sender country '\(entry.callingCode, privacy: .public)' not in allowed list \(allowedCodes, privacy: .public)")
                }
                else {
                    logger?.debug("  → countryAllowlist: sender country '\(entry.callingCode, privacy: .public)' is allowed")
                }
            }
            if result.action.isFiltered { break }
        }
        return result
    }

    private func isMataching(filter: Filter, body: String, sender: String) -> Bool {
        var messageForEvaluation = ""
        var textForEvaluation = filter.text ?? ""
        switch filter.filterTarget {
        case .all:
            messageForEvaluation = body + " " + sender
        case .sender:
            messageForEvaluation = sender
        case .body:
            messageForEvaluation = body
        }
        if filter.filterCase == .caseInsensitive {
            messageForEvaluation = messageForEvaluation.lowercased()
            textForEvaluation = textForEvaluation.lowercased()
        }
        guard filter.filterMatching == .exact else {
            return messageForEvaluation.contains(textForEvaluation)
        }
        var isMataching = false
        guard let range = messageForEvaluation.range(of: textForEvaluation, options: filter.filterCase.compareOption) else { return isMataching }
        let nsRange = NSRange(range, in: messageForEvaluation)
        isMataching = true
        if nsRange.location > 0,
           let indexBefore = messageForEvaluation.index(at: nsRange.location - 1),
           messageForEvaluation[indexBefore].isLetter {
            isMataching = false
        }
        if isMataching,
           nsRange.location + nsRange.length < messageForEvaluation.count,
           let indexAfter = messageForEvaluation.index(at: nsRange.location + nsRange.length),
           messageForEvaluation[indexAfter].isLetter {
            isMataching = false
        }
        return isMataching
    }
}
