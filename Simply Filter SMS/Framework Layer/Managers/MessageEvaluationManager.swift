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
    
    
    //MARK: Public API (MessageEvaluationManagerProtocol)
    func evaluateMessage(body: String, sender: String) -> ILMessageFilterAction {
        var action = ILMessageFilterAction.none
        
        // Priority #1 - Allow
        action = self.runUserFilters(type: .allow, body: body, sender: sender)
        guard !action.isFiltered else { return action }
        
        // Priority #2 - Deny
        action = self.runUserFilters(type: .deny, body: body, sender: sender)
        guard !action.isFiltered else { return action }
        
        // Priority #3 - Deny Language
        action = self.runUserFilters(type: .denyLanguage, body: body, sender: sender)
        guard !action.isFiltered else { return action }
        
        // Priority #4 - Automatic Filtering
        action = self.runAutomaticFilters(body: body, sender: sender)
        guard !action.isFiltered else { return action }
        
        // Priority #5 - Rules
        action = self.runFilterRules(body: body, sender: sender)
        
        if !action.isFiltered {
            action = .allow
        }
        
        return action
    }
    
    func setLogger(_ logger: Logger) {
        self.logger = logger
    }
    
    //MARK: - Private  -
    private var logger: Logger?
    private var persistentContainer: NSPersistentContainer?
    private(set) var context: NSManagedObjectContext
        
    private func runUserFilters(type: FilterType, body: String, sender: String) -> ILMessageFilterAction {
        var action = ILMessageFilterAction.none
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld", type.rawValue)
        
        guard let filters = try? self.context.fetch(fetchRequest) else {
            self.logger?.error("ERROR! While loading filters on MessageEvaluationManager.runUserFilters")
            return action
        }
        
        switch type {
        case .allow:
            for filter in filters {
                guard let filter = filter as? Filter,
                      self.isMataching(filter: filter, body: body, sender: sender) else { continue }
                
                action = .allow
                break
            }
            
        case .deny:
            for filter in filters {
                guard let filter = filter as? Filter,
                      self.isMataching(filter: filter, body: body, sender: sender) else { continue }
                
                action = filter.denyFolderType.action
                break
            }
            
        case .denyLanguage:
            for filter in filters {
                guard let filter = filter as? Filter else { continue }
                
                let language = NLLanguage(filterText: filter.text ?? "")
                
                if language != .undetermined,
                   NLLanguage.dominantLanguage(for: body) == language {
                    
                    action = filter.denyFolderType.action
                    break
                }
            }
        }
        
        return action
    }
    
    private func runAutomaticFilters(body: String, sender: String) -> ILMessageFilterAction {
        var action = ILMessageFilterAction.none
        let lowercasedBody = body.lowercased()
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        let cacheRequest: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        
        guard let automaticFiltersLanguageRecords = try? self.context.fetch(languageRequest),
              let cacheRow = try? self.context.fetch(cacheRequest).first,
              let filtersData = cacheRow.filtersData,
              let automaticFilterList = AutomaticFilterListsResponse(base64String: filtersData) else {
                  
                  self.logger?.error("ERROR! While loading cache on MessageEvaluationManager.runAutomaticFilters")
                  return action
              }
        
        for automaticFiltersLanguageRecord in automaticFiltersLanguageRecords {
            guard action == .none else { break }
            
            if automaticFiltersLanguageRecord.isActive,
               let langRawValue = automaticFiltersLanguageRecord.lang,
               let languageResponse = automaticFilterList.filterLists[langRawValue] {
                
                for allowedSender in languageResponse.allowSenders {
                    if sender == allowedSender {
                        action = .allow
                        break
                    }
                }
                
                guard !action.isFiltered else { break }
                
                for allowedBody in languageResponse.allowBody {
                    if lowercasedBody.contains(allowedBody.lowercased()) {
                        action = .allow
                        break
                    }
                }
                
                guard !action.isFiltered else { break }
                
                for deniedSender in languageResponse.denySender {
                    if sender == deniedSender {
                        action = .junk
                        break
                    }
                }
                
                guard !action.isFiltered else { break }
                
                for deniedBody in languageResponse.denyBody {
                    if lowercasedBody.contains(deniedBody.lowercased()) {
                        action = .junk
                        break
                    }
                }
            }
        }
        
        return action
    }
    
    private func runFilterRules(body: String, sender: String) -> ILMessageFilterAction {
        var action = ILMessageFilterAction.none
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        
        guard let activeAutomaticFiltersRuleRecords = try? self.context.fetch(ruleRequest) else {
            self.logger?.error("ERROR! While loading rules on MessageEvaluationManager.runFilterRules")
            return action
        }
        
        for activeRule in activeAutomaticFiltersRuleRecords {
            if let ruleType = activeRule.ruleType {
                switch ruleType {
                case .allUnknown:
                    action = .junk
                    break
                    
                case .links:
                    if body.containsLink {
                        action = .junk
                        break
                    }

                case .numbersOnly:
                    if let _ = sender.rangeOfCharacter(from: NSCharacterSet.letters) {
                        action = .junk
                        break
                    }
                    
                case .shortSender:
                    if sender.count <= Int(activeRule.selectedChoice) {
                        action = .junk
                        break
                    }
                    
                case .email:
                    if sender.containsEmail {
                        action = .junk
                        break
                    }
                }
            }
        }
        
        return action
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
