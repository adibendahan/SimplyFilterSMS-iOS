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
    
    //MARK: Public API (MessageEvaluationManagerProtocol)
    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult {
        
        var result = MessageEvaluationResult(action: .none)
        
        // Priority #1 - Allow
        result = self.runUserFilters(type: .allow, body: body, sender: sender)
        guard !result.response.action.isFiltered else { return result }
        
        // Priority #2 - Deny
        result = self.runUserFilters(type: .deny, body: body, sender: sender)
        guard !result.response.action.isFiltered else { return result }
        
        // Priority #3 - Deny Language
        result = self.runUserFilters(type: .denyLanguage, body: body, sender: sender)
        guard !result.response.action.isFiltered else { return result }
        
        // Priority #4 - Automatic Filtering
        result = self.runAutomaticFilters(body: body, sender: sender)
        guard !result.response.action.isFiltered else { return result }
        
        // Priority #5 - Rules
        result = self.runFilterRules(body: body, sender: sender)
        
        if !result.response.action.isFiltered {
            result = MessageEvaluationResult(action: .allow, reason: "testFilters_resultReason_noMatch"~)
        }
        
        return result
    }
    
    func setLogger(_ logger: Logger) {
        self.logger = logger
    }
    
    @available(iOS 16.0, *)
    func fetchChosenSubActions() -> ILMessageFilterCapabilitiesQueryResponse {
        let response = ILMessageFilterCapabilitiesQueryResponse()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ChosenSubActions")
        var chosenSubActions = kDefaultSubActions
        
        if let chosenSubActionsIds = try? self.context.fetch(fetchRequest), chosenSubActionsIds.count > 0 {
            chosenSubActions = chosenSubActionsIds.map {
                guard let chosenSubActions = $0 as? ChosenSubActions else { return DenyFolderType.junk }
                return DenyFolderType(rawValue: chosenSubActions.actionId) ?? .junk
            }
            chosenSubActions.removeAll(where: { !$0.isSubFolder})
        }

        response.transactionalSubActions = chosenSubActions.filter({ $0.parent == .transaction }).map({ $0.subAction ?? .none})
        response.promotionalSubActions = chosenSubActions.filter({ $0.parent == .promotion }).map({ $0.subAction ?? .none})
        
        return response
    }

    //MARK: - Private  -
    private var logger: Logger?
    private var persistentContainer: NSPersistentContainer?
    private(set) var context: NSManagedObjectContext
        
    private func runUserFilters(type: FilterType, body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld", type.rawValue)
        
        guard let filters = try? self.context.fetch(fetchRequest) else {
            self.logger?.error("ERROR! While loading filters on MessageEvaluationManager.runUserFilters")
            return result
        }
        
        switch type {
        case .allow:
            for filter in filters {
                guard let filter = filter as? Filter,
                      self.isMataching(filter: filter, body: body, sender: sender) else { continue }
                
                result = MessageEvaluationResult(action: .allow, reason: filter.text)
                break
            }
            
        case .deny:
            for filter in filters {
                guard let filter = filter as? Filter,
                      self.isMataching(filter: filter, body: body, sender: sender) else { continue }
                
                result = MessageEvaluationResult(action: filter.denyFolderType.action, reason: filter.text)
                result.response.addSubActionIfNeeded(evaluationManager: self, denyFolderType: filter.denyFolderType)
                
                break
            }
            
        case .denyLanguage:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                
                let language = NLLanguage(filterText: filter.text ?? "")
                
                if language != .undetermined,
                   NLLanguage.dominantLanguage(for: body) == language {
                    
                    result = MessageEvaluationResult(action: filter.denyFolderType.action, reason: language.localizedName)
                    result.response.addSubActionIfNeeded(evaluationManager: self, denyFolderType: filter.denyFolderType)
                    
                    break
                }
            }
        }
        
        return result
    }
    
    private func runAutomaticFilters(body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let lowercasedBody = body.lowercased()
        let lowercasedSender = sender.lowercased()
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        let cacheRequest: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        
        guard let automaticFiltersLanguageRecords = try? self.context.fetch(languageRequest),
              let cacheRow = try? self.context.fetch(cacheRequest).first,
              let filtersData = cacheRow.filtersData,
              let automaticFilterList = AutomaticFilterListsResponse(base64String: filtersData) else {
                  
                  self.logger?.error("ERROR! While loading cache on MessageEvaluationManager.runAutomaticFilters")
                  return result
              }
        
        for automaticFiltersLanguageRecord in automaticFiltersLanguageRecords {
            guard result.response.action == .none else { break }
            
            if automaticFiltersLanguageRecord.isActive,
               let langRawValue = automaticFiltersLanguageRecord.lang,
               let languageResponse = automaticFilterList.filterLists[langRawValue] {
                
                let lang = NLLanguage(rawValue: langRawValue)
                
                for allowedSender in languageResponse.allowSenders {
                    if lowercasedSender == allowedSender.lowercased() {
                        result = MessageEvaluationResult(action: .allow, reason: "\("autoFilter_title"~) (\(lang.localizedName ?? langRawValue))")
                        break
                    }
                }
                
                guard !result.response.action.isFiltered else { break }
                
                for allowedBody in languageResponse.allowBody {
                    if lowercasedBody.contains(allowedBody.lowercased()) {
                        result = MessageEvaluationResult(action: .allow, reason: "\("autoFilter_title"~) (\(lang.localizedName ?? langRawValue))")
                        break
                    }
                }
                
                guard !result.response.action.isFiltered else { break }
                
                for deniedSender in languageResponse.denySender {
                    if lowercasedSender == deniedSender.lowercased() {
                        result = MessageEvaluationResult(action: .junk, reason: "\("autoFilter_title"~) (\(lang.localizedName ?? langRawValue))")
                        break
                    }
                }
                
                guard !result.response.action.isFiltered else { break }
                
                for deniedBody in languageResponse.denyBody {
                    if lowercasedBody.contains(deniedBody.lowercased()) {
                        result = MessageEvaluationResult(action: .junk, reason: "\("autoFilter_title"~) (\(lang.localizedName ?? langRawValue))")
                        break
                    }
                }
            }
        }
        
        return result
    }
    
    private func runFilterRules(body: String, sender: String) -> MessageEvaluationResult {
        var result = MessageEvaluationResult(action: .none)
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        
        guard let activeAutomaticFiltersRuleRecords = try? self.context.fetch(ruleRequest) else {
            self.logger?.error("ERROR! While loading rules on MessageEvaluationManager.runFilterRules")
            return result
        }

        for activeRule in activeAutomaticFiltersRuleRecords {
            if let ruleType = activeRule.ruleType {
                switch ruleType {
                case .allUnknown:
                    result = MessageEvaluationResult(action: .junk, reason: "testFilters_resultReason_unknownSender"~)
                    break
                    
                case .links:
                    if body.containsLink {
                        result = MessageEvaluationResult(action: .junk, reason: "autoFilter_links_shortTitle"~)
                        break
                    }

                case .numbersOnly:
                    if let _ = sender.rangeOfCharacter(from: NSCharacterSet.letters) {
                        result = MessageEvaluationResult(action: .junk, reason: "autoFilter_numbersOnly_shortTitle"~)
                        break
                    }
                    
                case .shortSender:
                    if sender.count <= Int(activeRule.selectedChoice) {
                        result = MessageEvaluationResult(action: .junk, reason: "autoFilter_shortSender_shortTitle"~)
                        break
                    }
                    
                case .email:
                    if sender.containsEmail {
                        result = MessageEvaluationResult(action: .junk, reason: "autoFilter_email_shortTitle"~)
                        break
                    }
                    
                case .emojis:
                    if body.containsEmoji {
                        result = MessageEvaluationResult(action: .junk, reason: "autoFilter_emojis_shortTitle"~)
                        break
                    }
                }
            }
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


extension ILMessageFilterQueryResponse {
    convenience init(action: ILMessageFilterAction) {
        self.init()
        self.action = action
    }
    
    func addSubActionIfNeeded(evaluationManager: MessageEvaluationManagerProtocol,
                              denyFolderType: DenyFolderType) {
        
        if #available(iOS 16.0, *) {
            let chosenSubActions = evaluationManager.fetchChosenSubActions()

            if denyFolderType.isSubFolder,
               let subAction = denyFolderType.subAction,
               (chosenSubActions.promotionalSubActions.contains(subAction) ||
                chosenSubActions.transactionalSubActions.contains(subAction)) {
                
                self.subAction = subAction
            }
        }
    }
}
