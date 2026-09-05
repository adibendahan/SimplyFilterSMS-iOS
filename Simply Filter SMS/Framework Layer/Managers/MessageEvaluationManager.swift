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

    /// Production readers open a fresh read-only store for each query. A failed open
    /// is retried on the next query, and no live app context participates.
    init(inMemory: Bool = false, storeURL: URL? = nil) {
        if inMemory {
            let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.loadPersistentStores { _, _ in }
            contextSource = .owned(container)
        } else {
            contextSource = .saved(storeURL)
        }
    }

    init(persistanceManager: PersistanceManagerProtocol) {
        contextSource = .persistance(persistanceManager)
    }

    init(context: NSManagedObjectContext) {
        contextSource = .query(context)
    }

    private let evaluationQueue = DispatchQueue(label: "com.simplyfiltersms.saved-evaluation")

    func evaluateMessage(body: String, sender: String, completion: @escaping (MessageEvaluationResult) -> Void) {
        evaluationQueue.async {
            completion(self.evaluateMessage(body: body, sender: sender))
        }
    }

    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult {
        if case .saved(let overrideURL) = contextSource {
            do {
                let url = try overrideURL ?? AppPersistentCloudKitContainer.sharedStoreURL()
                guard FileManager.default.fileExists(atPath: url.path) else {
                    throw NSError(domain: "SavedRulesStore", code: 1)
                }
                let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory, isReadOnly: true)
                container.persistentStoreDescriptions.first!.url = url
                // Deliberately synchronous on the caller's worker queue. No invented
                // timeout, semaphore race, or retained failed container.
                container.persistentStoreDescriptions.first!.shouldAddStoreAsynchronously = false
                var loadError: Error?
                container.loadPersistentStores { _, error in loadError = error }
                if let loadError { throw loadError }
                guard !container.persistentStoreCoordinator.persistentStores.isEmpty else {
                    throw NSError(domain: "SavedRulesStore", code: 2)
                }
                let context = container.newBackgroundContext()
                defer {
                    context.performAndWait { context.reset() }
                    for store in container.persistentStoreCoordinator.persistentStores {
                        try? container.persistentStoreCoordinator.remove(store)
                    }
                }
                return context.performAndWait {
                    do {
                        try context.setQueryGenerationFrom(.current)
                        let evaluator = MessageEvaluationManager(context: context)
                        return try evaluator.evaluateRules(body: body, sender: sender)
                    } catch {
                        return self.failure(error, status: .readFailed)
                    }
                }
            } catch {
                return failure(error, status: .storeUnavailable)
            }
        }
        return context.performAndWait {
            do { return try self.evaluateRules(body: body, sender: sender) }
            catch { return self.failure(error, status: .readFailed) }
        }
    }

    private func failure(_ error: Error, status: MessageEvaluationStatus) -> MessageEvaluationResult {
        let error = error as NSError
        logger?.error("Rules evaluation failed: status=\(status.rawValue, privacy: .public) domain=\(error.domain, privacy: .public) code=\(error.code, privacy: .public)")
        return MessageEvaluationResult(action: .allow, match: .storeUnavailable, status: status)
    }

    private func evaluateRules(body: String, sender: String) throws -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        // Priority #1 - Allow Filters
        result = try self.runUserFilters(type: .allow, body: body, sender: sender)
        guard !result.action.isFiltered else {
            return result
        }
        // Priority #2 - allUnknown (absolute gate, overrides everything)
        result = try self.runAllUnknownRule()
        guard !result.action.isFiltered else {
            return result
        }
        // Priority #3 - Automatic Filters (allow)
        result = try self.runAutomaticFiltersAllow(body: body, sender: sender)
        guard !result.action.isFiltered else {
            return result
        }
        // Priority #4 - Filter Rules
        result = try self.runFilterRules(body: body, sender: sender)
        guard !result.action.isFiltered else {
            return result
        }
        // Priority #5 - Deny Filters
        result = try self.runUserFilters(type: .deny, body: body, sender: sender)
        guard !result.action.isFiltered else {
            return result
        }
        // Priority #6 - Deny Language Filters
        result = try self.runUserFilters(type: .denyLanguage, body: body, sender: sender)
        guard !result.action.isFiltered else {
            return result
        }
        // Priority #7 - Automatic Filters (deny)
        result = try self.runAutomaticFiltersDeny(body: body, sender: sender)
        if !result.action.isFiltered {
            result = MessageEvaluationResult(action: .allow, match: .noMatch)
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
        case .query(let context):
            return context
        case .saved:
            preconditionFailure("Saved readers do not expose a managed object context")
        }
    }

    //MARK: - Private -

    private enum ContextSource {
        case persistance(PersistanceManagerProtocol)
        case owned(NSPersistentCloudKitContainer)
        case saved(URL?)
        case query(NSManagedObjectContext)
    }

    private var logger: Logger?
    private let contextSource: ContextSource

    private func runAllUnknownRule() throws -> MessageEvaluationResult {
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "ruleId == %ld AND isActive == %@",
                                            RuleType.allUnknown.rawValue,
                                            NSNumber(value: true))
        guard try !self.context.fetch(ruleRequest).isEmpty else {
            return MessageEvaluationResult(action: .none)
        }
        return MessageEvaluationResult(action: .junk, match: .smartFilter("testFilters_resultReason_unknownSender"~))
    }

    private func runUserFilters(type: FilterType, body: String, sender: String) throws -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld", type.rawValue)
        let filters = try self.context.fetch(fetchRequest)
        switch type {
        case .allow:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let matched = self.isMatching(filter: filter, body: body, sender: sender)
                guard matched else { continue }
                result = MessageEvaluationResult(action: .allow, match: .userFilter(filter.text ?? ""))
                break
            }
        case .deny:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let matched = self.isMatching(filter: filter, body: body, sender: sender)
                guard matched else { continue }
                result = MessageEvaluationResult(action: filter.denyFolderType.action, match: .userFilter(filter.text ?? ""))
                break
            }
        case .denyLanguage:
            let detectedLanguage = NLLanguage.dominantLanguage(for: body)
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let language = NLLanguage(filterText: filter.text ?? "")
                let matched = language != .undetermined && detectedLanguage == language
                guard matched else { continue }
                result = MessageEvaluationResult(action: filter.denyFolderType.action, match: .userFilter(language.localizedName ?? language.rawValue))
                break
            }
        }
        return result
    }

    private func loadAutomaticFilterCache() throws -> ([AutomaticFiltersLanguage], AutomaticFilterListsResponse)? {
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        let cacheRequest: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        let languageRecords = try self.context.fetch(languageRequest)
        guard let cacheRow = try self.context.fetch(cacheRequest).first else { return nil }
        guard let filtersData = cacheRow.filtersData,
              let filterList = AutomaticFilterListsResponse(base64String: filtersData) else {
            throw NSError(domain: "SavedRulesCache", code: 1)
        }
        return (languageRecords, filterList)
    }

    private func runAutomaticFiltersAllow(body: String, sender: String) throws -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let lowercasedBody = body.lowercased()
        let lowercasedSender = sender.lowercased()
        guard let (languageRecords, filterList) = try self.loadAutomaticFilterCache() else {
            return result
        }
        for record in languageRecords {
            guard result.action == .none,
                  record.isActive,
                  let langRawValue = record.lang,
                  let languageResponse = filterList.filterLists[langRawValue] else { continue }
            let lang = NLLanguage(rawValue: langRawValue)
            for allowedSender in languageResponse.allowSenders {
                if lowercasedSender == allowedSender.lowercased() {
                    result = MessageEvaluationResult(action: .allow, match: .automaticFilter(lang.localizedName ?? langRawValue))
                    break
                }
            }
            guard !result.action.isFiltered else { break }
            for allowedBody in languageResponse.allowBody {
                if lowercasedBody.contains(allowedBody.lowercased()) {
                    result = MessageEvaluationResult(action: .allow, match: .automaticFilter(lang.localizedName ?? langRawValue))
                    break
                }
            }
        }
        return result
    }

    private func runAutomaticFiltersDeny(body: String, sender: String) throws -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let lowercasedBody = body.lowercased()
        let lowercasedSender = sender.lowercased()
        guard let (languageRecords, filterList) = try self.loadAutomaticFilterCache() else {
            return result
        }
        for record in languageRecords {
            guard result.action == .none,
                  record.isActive,
                  let langRawValue = record.lang,
                  let languageResponse = filterList.filterLists[langRawValue] else { continue }
            let lang = NLLanguage(rawValue: langRawValue)
            for deniedSender in languageResponse.denySender {
                if lowercasedSender == deniedSender.lowercased() {
                    result = MessageEvaluationResult(action: .junk, match: .automaticFilter(lang.localizedName ?? langRawValue))
                    break
                }
            }
            guard !result.action.isFiltered else { break }
            for deniedBody in languageResponse.denyBody {
                if lowercasedBody.contains(deniedBody.lowercased()) {
                    result = MessageEvaluationResult(action: .junk, match: .automaticFilter(lang.localizedName ?? langRawValue))
                    break
                }
            }
        }
        return result
    }

    private func runFilterRules(body: String, sender: String) throws -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        let activeRules = try self.context.fetch(ruleRequest)
        for activeRule in activeRules {
            guard let ruleType = activeRule.ruleType else { continue }
            switch ruleType {
            case .allUnknown:
                break
            case .links:
                if body.containsLink {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                }
            case .numbersOnly:
                if sender.rangeOfCharacter(from: .letters) != nil {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                }
            case .shortSender:
                if sender.count <= Int(activeRule.selectedChoice) {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                }
            case .email:
                if sender.containsEmail {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                }
            case .emojis:
                if body.containsEmoji {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                }
            case .countryAllowlist:
                guard let json = activeRule.selectedCountries,
                      let data = json.data(using: .utf8),
                      let allowedCodes = try? JSONDecoder().decode([String].self, from: data),
                      !allowedCodes.isEmpty else {
                    break
                }
                guard let entry = CallingCodes.callingCode(for: sender) else {
                    break
                }
                if !allowedCodes.contains(entry.callingCode) {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(ruleType.shortTitle))
                }
            }
            if result.action.isFiltered { break }
        }
        return result
    }

    private func isMatching(filter: Filter, body: String, sender: String) -> Bool {
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
        if filter.filterMatching == .regex {
            guard let regex = try? Regex(textForEvaluation) else { return false }
            return messageForEvaluation.contains(regex)
        }
        if filter.filterCase == .caseInsensitive {
            messageForEvaluation = messageForEvaluation.lowercased()
            textForEvaluation = textForEvaluation.lowercased()
        }
        guard filter.filterMatching == .exact else {
            return messageForEvaluation.contains(textForEvaluation)
        }
        var isMatching = false
        guard let range = messageForEvaluation.range(of: textForEvaluation, options: filter.filterCase.compareOption) else { return isMatching }
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
