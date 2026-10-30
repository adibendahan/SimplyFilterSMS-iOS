//
//  MessageEvaluationManager.swift
//  Simply Filter SMS
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

    init(inMemory: Bool = false) {
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory, isReadOnly: !inMemory)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions.first!.cloudKitContainerOptions = nil
        }

        container.persistentStoreDescriptions.first!.shouldAddStoreAsynchronously = false

        var loadError: Error?
        container.loadPersistentStores { (_, error) in
            loadError = error
        }
        if let loadError {
            let logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "evaluation")
            logger.error("Owned store load failed: \(loadError.localizedDescription, privacy: .public)")
        }
        else {
            container.viewContext.stalenessInterval = 0
            container.viewContext.automaticallyMergesChangesFromParent = true
        }

        self.contextSource = .owned(container)
    }

    init(persistanceManager: PersistanceManagerProtocol) {
        self.contextSource = .persistance(persistanceManager)
    }

    //MARK: - Public API (MessageEvaluationManagerProtocol) -

    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult {
        if case .owned(let container) = self.contextSource,
           container.persistentStoreCoordinator.persistentStores.isEmpty {
            self.logger?.error("Owned store unavailable — skipping evaluation (allow)")
            return MessageEvaluationResult(action: .allow, match: .storeUnavailable)
        }

        return self.context.performAndWait {
            self.evaluateRules(body: body, sender: sender)
        }
    }

    private func evaluateRules(body: String, sender: String) -> MessageEvaluationResult {
        logger?.debug("━━━━ Evaluating message | sender: '\(sender, privacy: .public)' | body: '\(body, privacy: .public)' ━━━━")
        var result = MessageEvaluationResult(action: .none)
        defer {
            logger?.debug("━━━━ Final decision: action=\(result.action.logName, privacy: .public), reason='\(result.reason ?? "", privacy: .public)' ━━━━")
        }
        result = self.runUserFilters(type: .allow, body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #1 (Allow Filters) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #1 (Allow Filters) → no match, continuing")
        result = self.runAllUnknownRule()
        guard !result.action.isFiltered else {
            logger?.debug("Priority #2 (allUnknown) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #2 (allUnknown) → not active, continuing")
        let activeFilterLists = self.loadActiveFilterLists()
        result = self.runAutomaticFilters(type: .allow, activeFilterLists: activeFilterLists, body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #3 (Automatic Filters Allow) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #3 (Automatic Filters Allow) → no match, continuing")
        result = self.runFilterRules(body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #4 (Filter Rules) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #4 (Filter Rules) → no match, continuing")
        result = self.runUserFilters(type: .deny, body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #5 (Deny Filters) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #5 (Deny Filters) → no match, continuing")
        result = self.runUserFilters(type: .denyLanguage, body: body, sender: sender)
        guard !result.action.isFiltered else {
            logger?.debug("Priority #6 (Deny Language Filters) → DECISION: \(result.action.logName, privacy: .public)")
            return result
        }
        logger?.debug("Priority #6 (Deny Language Filters) → no match, continuing")
        result = self.runAutomaticFilters(type: .deny, activeFilterLists: activeFilterLists, body: body, sender: sender)
        if !result.action.isFiltered {
            result = MessageEvaluationResult(action: .allow, match: .noMatch)
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

    var context: NSManagedObjectContext {
        switch self.contextSource {
        case .persistance(let persistanceManager):
            return persistanceManager.context
        case .owned(let container):
            return container.viewContext
        }
    }

    //MARK: - Private -

    private enum ContextSource {
        case persistance(PersistanceManagerProtocol)
        case owned(NSPersistentCloudKitContainer)
    }

    private var logger: Logger?
    private let contextSource: ContextSource

    private func runAllUnknownRule() -> MessageEvaluationResult {
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "ruleId == %ld AND isActive == %@",
                                            RuleType.allUnknown.rawValue,
                                            NSNumber(value: true))
        guard (try? self.context.fetch(ruleRequest))?.isEmpty == false else {
            return MessageEvaluationResult(action: .none)
        }
        logger?.debug("[allUnknown] rule is active")
        return MessageEvaluationResult(action: .junk, match: .smartFilter("testFilters_resultReason_unknownSender"~))
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
                let matched = self.isMatching(filter: filter, body: body, sender: sender)
                logger?.debug("  Checking allow filter '\(filter.text ?? "?", privacy: .public)' [target: \(filter.filterTarget.logDescription, privacy: .public), matching: \(filter.filterMatching.logDescription, privacy: .public), case: \(filter.filterCase.logDescription, privacy: .public)] → \(matched ? "MATCH" : "no match", privacy: .public)")
                guard matched else { continue }
                result = MessageEvaluationResult(action: .allow, match: .userFilter(filter.text ?? ""))
                logger?.debug("  → Returning ALLOW")
                break
            }
        case .deny:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let matched = self.isMatching(filter: filter, body: body, sender: sender)
                logger?.debug("  Checking deny filter '\(filter.text ?? "?", privacy: .public)' [target: \(filter.filterTarget.logDescription, privacy: .public), matching: \(filter.filterMatching.logDescription, privacy: .public), case: \(filter.filterCase.logDescription, privacy: .public), folder: \(filter.denyFolderType.logDescription, privacy: .public)] → \(matched ? "MATCH" : "no match", privacy: .public)")
                guard matched else { continue }
                result = MessageEvaluationResult(action: filter.denyFolderType.action, match: .userFilter(filter.text ?? ""))
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
                result = MessageEvaluationResult(action: filter.denyFolderType.action, match: .userFilter(language.localizedName ?? language.rawValue))
                logger?.debug("  → Returning \(result.action.logName, privacy: .public) for language '\(language.localizedName ?? language.rawValue, privacy: .public)'")
                break
            }
        }
        return result
    }

    private func loadActiveFilterLists() -> ActiveFilterLists? {
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        guard let languageRecords = try? self.context.fetch(languageRequest) else { return nil }

        var activeLanguages: Set<String> = []
        for languageRecord in languageRecords {
            guard let lang = languageRecord.lang, languageRecord.isActive else { continue }
            activeLanguages.insert(lang)
        }
        guard !activeLanguages.isEmpty else { return nil }

        let cacheRequest: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        guard let cacheRow = try? self.context.fetch(cacheRequest).first,
              let filtersData = cacheRow.filtersData else { return nil }

        return ActiveFilterLists(encoded: filtersData, activeLanguages: activeLanguages)
    }

    private func runAutomaticFilters(type: FilterType, activeFilterLists: ActiveFilterLists?, body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        guard let activeFilterLists = activeFilterLists else {
            logger?.debug("[Automatic Filters \(type.logDescription, privacy: .public)] no active lists, skipping")
            return result
        }
        logger?.debug("[Automatic Filters \(type.logDescription, privacy: .public)] \(activeFilterLists.lists.count, privacy: .public) active list(s)")
        for list in activeFilterLists.lists {
            for record in list.records {
                guard FilterType(exportKey: record.type) == type,
                      let candidate = FilterTransferCandidate(record: record) else { continue }

                let matched = self.isMatching(text: candidate.text,
                                              target: candidate.filterTarget,
                                              matching: candidate.filterMatching,
                                              filterCase: candidate.filterCase,
                                              body: body,
                                              sender: sender)
                guard matched else { continue }

                let action: ILMessageFilterAction = type == .allow ? .allow : candidate.denyFolder.action
                result = MessageEvaluationResult(action: action, match: .automaticFilter(list.name))
                logger?.debug("  → \(result.action.logName, privacy: .public): matched '\(candidate.text, privacy: .public)' [\(list.name, privacy: .public)]")
                return result
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
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                    logger?.debug("  → JUNK: links — body contains a link")
                }
                else {
                    logger?.debug("  → no link detected in body")
                }
            case .numbersOnly:
                if sender.rangeOfCharacter(from: .letters) != nil {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                    logger?.debug("  → JUNK: numbersOnly — sender '\(sender, privacy: .public)' triggered rule")
                }
                else {
                    logger?.debug("  → sender '\(sender, privacy: .public)' did not trigger numbersOnly rule")
                }
            case .shortSender:
                if sender.count <= Int(activeRule.selectedChoice) {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                    logger?.debug("  → JUNK: shortSender — sender length \(sender.count, privacy: .public) ≤ threshold \(Int(activeRule.selectedChoice), privacy: .public)")
                }
                else {
                    logger?.debug("  → sender length \(sender.count, privacy: .public) > threshold \(Int(activeRule.selectedChoice), privacy: .public), not short")
                }
            case .email:
                if sender.containsEmail {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                    logger?.debug("  → JUNK: email — sender '\(sender, privacy: .public)' looks like an email address")
                }
                else {
                    logger?.debug("  → sender '\(sender, privacy: .public)' is not an email address")
                }
            case .emojis:
                if body.containsEmoji {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
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
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
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

    private func isMatching(filter: Filter, body: String, sender: String) -> Bool {
        return self.isMatching(text: filter.text ?? "",
                               target: filter.filterTarget,
                               matching: filter.filterMatching,
                               filterCase: filter.filterCase,
                               body: body,
                               sender: sender)
    }

    private func isMatching(text: String, target: FilterTarget, matching: FilterMatching, filterCase: FilterCase, body: String, sender: String) -> Bool {
        var messageForEvaluation = ""
        var textForEvaluation = text
        switch target {
        case .all:
            messageForEvaluation = body + " " + sender
        case .sender:
            messageForEvaluation = sender
        case .body:
            messageForEvaluation = body
        }
        if matching == .regex {
            guard let regex = try? Regex(textForEvaluation) else { return false }
            return messageForEvaluation.contains(regex)
        }
        if filterCase == .caseInsensitive {
            messageForEvaluation = messageForEvaluation.lowercased()
            textForEvaluation = textForEvaluation.lowercased()
        }
        guard matching == .exact else {
            return messageForEvaluation.contains(textForEvaluation)
        }
        var isMatching = false
        guard let range = messageForEvaluation.range(of: textForEvaluation, options: filterCase.compareOption) else { return isMatching }
        let nsRange = NSRange(range, in: messageForEvaluation)
        isMatching = true
        if nsRange.location > 0,
           let indexBefore = messageForEvaluation.index(at: nsRange.location - 1),
           messageForEvaluation[indexBefore].isLetter {
            isMatching = false
        }
        if isMatching,
           nsRange.location + nsRange.length < messageForEvaluation.count,
           let indexAfter = messageForEvaluation.index(at: nsRange.location + nsRange.length),
           messageForEvaluation[indexAfter].isLetter {
            isMatching = false
        }
        return isMatching
    }
}
