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
            Log.error("owned store load failed", error: loadError)
        }
        else {
            container.viewContext.stalenessInterval = 0
            container.viewContext.automaticallyMergesChangesFromParent = true
        }

        self.contextSource = .owned(container)
    }

    init(persistenceManager: PersistenceManagerProtocol) {
        self.contextSource = .persistence(persistenceManager)
    }

    //MARK: - Public API (MessageEvaluationManagerProtocol) -

    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult {
        if case .owned(let container) = self.contextSource,
           container.persistentStoreCoordinator.persistentStores.isEmpty {
            Log.error("owned store unavailable → allowed without evaluation")
            return MessageEvaluationResult(action: .allow, match: .storeUnavailable)
        }

        return self.context.performAndWait {
            self.evaluateRules(body: body, sender: sender)
        }
    }

    private func evaluateRules(body: String, sender: String) -> MessageEvaluationResult {
        Log.debug("evaluating, sender: \(sender), body: \(body)")
        var result = MessageEvaluationResult(action: .none)
        defer {
            Log.debug("evaluated, action: \(result.action.logName), reason: \(result.reason)")
        }
        result = self.runUserFilters(type: .allow, body: body, sender: sender)
        guard !result.action.isFiltered else {
            Log.debug("#1 allow filters → \(result.action.logName)")
            return result
        }
        Log.debug("#1 allow filters → no match")

        result = self.runAllUnknownRule()
        guard !result.action.isFiltered else {
            Log.debug("#2 all unknown senders → \(result.action.logName)")
            return result
        }
        Log.debug("#2 all unknown senders → no match")

        let activeFilterLists = self.loadActiveFilterLists()
        result = self.runFilterLists(type: .allow, activeFilterLists: activeFilterLists, body: body, sender: sender)
        guard !result.action.isFiltered else {
            Log.debug("#3 AI allow lists → \(result.action.logName)")
            return result
        }
        Log.debug("#3 AI allow lists → no match")

        result = self.runSmartFilters(body: body, sender: sender)
        guard !result.action.isFiltered else {
            Log.debug("#4 filter rules → \(result.action.logName)")
            return result
        }
        Log.debug("#4 filter rules → no match")

        result = self.runUserFilters(type: .deny, body: body, sender: sender)
        guard !result.action.isFiltered else {
            Log.debug("#5 deny filters → \(result.action.logName)")
            return result
        }
        Log.debug("#5 deny filters → no match")

        result = self.runUserFilters(type: .denyLanguage, body: body, sender: sender)
        guard !result.action.isFiltered else {
            Log.debug("#6 language filters → \(result.action.logName)")
            return result
        }
        Log.debug("#6 language filters → no match")

        result = self.runFilterLists(type: .deny, activeFilterLists: activeFilterLists, body: body, sender: sender)
        guard !result.action.isFiltered else {
            Log.debug("#7 AI deny lists → \(result.action.logName)")
            return result
        }
        Log.debug("#7 AI deny lists → no match")
        result = MessageEvaluationResult(action: .allow, match: .noMatch)
        return result
    }

    var context: NSManagedObjectContext {
        switch self.contextSource {
        case .persistence(let persistenceManager):
            return persistenceManager.context
        case .owned(let container):
            return container.viewContext
        }
    }

    //MARK: - Private -

    private enum ContextSource {
        case persistence(PersistenceManagerProtocol)
        case owned(NSPersistentCloudKitContainer)
    }

    private let contextSource: ContextSource

    private func runAllUnknownRule() -> MessageEvaluationResult {
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "ruleId == %ld AND isActive == %@",
                                            SmartFilterType.allUnknown.rawValue,
                                            NSNumber(value: true))
        guard self.fetch(ruleRequest)?.isEmpty == false else {
            return MessageEvaluationResult(action: .none)
        }
        return MessageEvaluationResult(action: .junk, match: .smartFilter("testFilters_resultReason_unknownSender"~))
    }

    private func runUserFilters(type: FilterType, body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld", type.rawValue)
        guard let filters = self.fetch(fetchRequest) else { return result }

        switch type {
        case .allow:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let matched = self.isMatching(filter: filter, body: body, sender: sender)
                Log.debug("filter checked, type: \(type), text: \(filter.text), target: \(filter.filterTarget), matching: \(filter.filterMatching), case: \(filter.filterCase) → \(matched: matched)")
                guard matched else { continue }
                result = MessageEvaluationResult(action: .allow, match: .userFilter(filter.text ?? ""))
                break
            }
        case .deny:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let matched = self.isMatching(filter: filter, body: body, sender: sender)
                Log.debug("filter checked, type: \(type), text: \(filter.text), target: \(filter.filterTarget), matching: \(filter.filterMatching), case: \(filter.filterCase), folder: \(filter.messageFolder) → \(matched: matched)")
                guard matched else { continue }
                result = MessageEvaluationResult(action: filter.messageFolder.action, match: .userFilter(filter.text ?? ""))
                break
            }
        case .denyLanguage:
            let detectedLanguage = NLLanguage.dominantLanguage(for: body)
            let detectedDescription = detectedLanguage?.rawValue ?? "undetermined"
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                let language = NLLanguage(filterText: filter.text ?? "")
                let matched = language != .undetermined && detectedLanguage == language
                Log.debug("filter checked, type: \(type), language: \(language.rawValue), detected: \(detectedDescription), folder: \(filter.messageFolder) → \(matched: matched)")
                guard matched else { continue }
                result = MessageEvaluationResult(action: filter.messageFolder.action, match: .userFilter(language.localizedName ?? language.rawValue))
                break
            }
        }
        return result
    }

    private func loadActiveFilterLists() -> ActiveFilterLists? {
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        guard let languageRecords = self.fetch(languageRequest) else { return nil }

        var activeLanguages: Set<String> = []
        for languageRecord in languageRecords {
            guard let lang = languageRecord.lang, languageRecord.isActive else { continue }
            activeLanguages.insert(lang)
        }
        guard !activeLanguages.isEmpty else {
            Log.debug("no active languages → AI lists skipped")
            return nil
        }

        guard let filtersData = self.loadCachedFilterLists() else {
            Log.debug("no cache row, languages: \(activeLanguages) → AI lists skipped")
            return nil
        }

        guard let activeFilterLists = ActiveFilterLists(encoded: filtersData, activeLanguages: activeLanguages) else {
            Log.debug("cache row doesn't decode, languages: \(activeLanguages) → AI lists skipped")
            return nil
        }
        let listNames = activeFilterLists.lists.map(\.name)
        Log.debug("AI lists loaded, languages: \(activeLanguages), lists: \(listNames)")
        return activeFilterLists
    }

    private func loadCachedFilterLists() -> String? {
        let cacheRequest: NSFetchRequest<FilterListsCache> = FilterListsCache.fetchRequest()
        cacheRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FilterListsCache.age, ascending: false)]
        if let encodedSnapshot = self.fetch(cacheRequest)?.first?.data {
            return encodedSnapshot
        }

        let legacyCacheRequest: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        legacyCacheRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AutomaticFiltersCache.age, ascending: false)]
        guard let encodedLegacyCache = self.fetch(legacyCacheRequest)?.first?.filtersData else { return nil }
        Log.debug("no 3.3 cache → reading the 3.2 cache")
        return FilterListsSnapshot(legacyEncoded: encodedLegacyCache)?.encoded
    }

    private func runFilterLists(type: FilterType, activeFilterLists: ActiveFilterLists?, body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        guard let activeFilterLists = activeFilterLists else { return result }

        for filterList in activeFilterLists.lists {
            for record in filterList.records {
                guard FilterType(exportKey: record.type) == type else { continue }
                guard let listFilter = FilterTransferCandidate(record: record) else {
                    Log.debug("AI list record invalid, list: \(filterList.name), type: \(record.type), text: \(record.text) → skipped")
                    continue
                }

                let matched = self.isMatching(text: listFilter.text,
                                              target: listFilter.filterTarget,
                                              matching: listFilter.filterMatching,
                                              filterCase: listFilter.filterCase,
                                              body: body,
                                              sender: sender)
                guard matched else { continue }

                let action: ILMessageFilterAction
                switch type {
                case .allow:
                    action = .allow
                case .deny, .denyLanguage:
                    action = listFilter.denyFolder.action
                }
                result = MessageEvaluationResult(action: action, match: .filterList(filterList.name))
                Log.debug("AI list record checked, text: \(listFilter.text), type: \(type), list: \(filterList.name), target: \(listFilter.filterTarget), matching: \(listFilter.filterMatching), case: \(listFilter.filterCase) → match")
                return result
            }
        }
        let listNames = activeFilterLists.lists.map(\.name)
        Log.debug("AI list records checked, type: \(type), lists: \(listNames) → no match")
        return result
    }

    private func runSmartFilters(body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        guard let activeRules = self.fetch(ruleRequest) else { return result }

        for activeRule in activeRules {
            guard let smartFilterType = activeRule.smartFilterType else { continue }
            switch smartFilterType {
            case .allUnknown:
                break
            case .links:
                if body.containsLink {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(smartFilterType.shortTitle))
                    Log.debug("rule checked, rule: \(smartFilterType), bodyHasLink: \(true) → match")
                }
                else {
                    Log.debug("rule checked, rule: \(smartFilterType), bodyHasLink: \(false) → no match")
                }
            case .numbersOnly:
                if sender.rangeOfCharacter(from: .letters) != nil {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(smartFilterType.shortTitle))
                    Log.debug("rule checked, rule: \(smartFilterType), sender: \(sender), senderHasLetters: \(true) → match")
                }
                else {
                    Log.debug("rule checked, rule: \(smartFilterType), sender: \(sender), senderHasLetters: \(false) → no match")
                }
            case .shortSender:
                let threshold = Int(activeRule.selectedChoice)
                if sender.count <= threshold {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(smartFilterType.shortTitle))
                    Log.debug("rule checked, rule: \(smartFilterType), length: \(sender.count), threshold: \(threshold) → match")
                }
                else {
                    Log.debug("rule checked, rule: \(smartFilterType), length: \(sender.count), threshold: \(threshold) → no match")
                }
            case .email:
                if sender.containsEmail {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(smartFilterType.shortTitle))
                    Log.debug("rule checked, rule: \(smartFilterType), sender: \(sender), senderIsEmail: \(true) → match")
                }
                else {
                    Log.debug("rule checked, rule: \(smartFilterType), sender: \(sender), senderIsEmail: \(false) → no match")
                }
            case .emojis:
                if body.containsEmoji {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(smartFilterType.shortTitle))
                    Log.debug("rule checked, rule: \(smartFilterType), bodyHasEmojis: \(true) → match")
                }
                else {
                    Log.debug("rule checked, rule: \(smartFilterType), bodyHasEmojis: \(false) → no match")
                }
            case .countryAllowlist:
                let json = activeRule.selectedCountries ?? "[]"
                let allowedCodes: [String]
                do {
                    allowedCodes = try JSONDecoder().decode([String].self, from: Data(json.utf8))
                } catch {
                    Log.error("countries don't decode, rule: \(smartFilterType), json: \(json) → skipped", error: error)
                    break
                }
                guard !allowedCodes.isEmpty else {
                    Log.debug("rule checked, rule: \(smartFilterType), allowed: '[]' → skipped")
                    break
                }
                guard let entry = CallingCodes.callingCode(for: sender) else {
                    Log.debug("rule checked, rule: \(smartFilterType), sender: \(sender), country: nil → skipped")
                    break
                }
                if !allowedCodes.contains(entry.callingCode) {
                    result = MessageEvaluationResult(action: .junk, match: .smartFilter(smartFilterType.shortTitle))
                    Log.debug("rule checked, rule: \(smartFilterType), country: \(entry.callingCode), allowed: \(allowedCodes) → match")
                }
                else {
                    Log.debug("rule checked, rule: \(smartFilterType), country: \(entry.callingCode), allowed: \(allowedCodes) → no match")
                }
            }
            if result.action.isFiltered { break }
        }
        return result
    }

    private func fetch<T: NSFetchRequestResult>(_ request: NSFetchRequest<T>) -> [T]? {
        do {
            return try self.context.fetch(request)
        } catch {
            Log.error("fetch failed, entity: \(request.entityName)", error: error)
            return nil
        }
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
            do {
                let regex = try Regex(textForEvaluation)
                return messageForEvaluation.contains(regex)
            } catch {
                Log.error("invalid regex, text: \(private: textForEvaluation) → no match", error: error)
                return false
            }
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
