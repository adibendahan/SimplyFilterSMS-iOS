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

//MARK: - Protocol -
protocol MessageEvaluationManagerProtocol {
    var context: NSManagedObjectContext { get }
    
    func evaluateMessage(body: String, sender: String) -> ILMessageFilterAction
    func setLogger(_ logger: Logger)
}


//MARK: - Implementation -
class MessageEvaluationManager: MessageEvaluationManagerProtocol {
    
    
    //MARK: - Initialization -
    init(inMemory: Bool = false) {
        let isReadOnly = inMemory ? false : true
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory, isReadOnly: isReadOnly)

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("ERROR! While initializing MessageEvaluationManager: \(error), \(error.userInfo)")
            }
        })
        
        self.persistentContainer = container
        self.context = container.viewContext
    }
    
    
    //MARK: Public API (MessageEvaluationManagerProtocol)
    func evaluateMessage(body: String, sender: String) -> ILMessageFilterAction {
        var action = ILMessageFilterAction.none
        
        // Priority #1 - Allow
        action = self.runUserFilters(type: .allow, body: body, sender: sender)
        guard action != .allow else { return action }
        
        // Priority #2 - Rules
        action = self.runFilterRules(body: body, sender: sender)
        guard !action.isFiltered else { return action }
            
        // Priority #3 - Deny
        action = self.runUserFilters(type: .deny, body: body, sender: sender)
        guard !action.isFiltered else { return action }
            
        // Priority #4 - Deny Language
        action = self.runUserFilters(type: .denyLanguage, body: body, sender: sender)
        guard !action.isFiltered else { return action }
            
        // Priority #5 - Automatic Filtering
        action = self.runAutomaticFilters(body: body, sender: sender)
        
        if action == .none {
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
        let messageText = "\(sender) \(body)"
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld", type.rawValue)
        
        guard let filters = try? self.context.fetch(fetchRequest) else {
            self.logger?.error("ERROR! While loading filters on MessageEvaluationManager.runUserFilters")
            return action
        }
        
        switch type {
        case .allow:
            for filter in filters {
                if let text = filter.value(forKey: "text") as? String,
                   messageText.contains(text.lowercased()) {
                    
                    action = .allow
                }
            }
            
        case .deny:
            for filter in filters {
                if let text = filter.value(forKey: "text") as? String,
                   messageText.contains(text.lowercased()) {
                    
                    if let denyFolderValue = filter.value(forKey: "folderType") as? Int64,
                       let denyFolder = DenyFolderType(rawValue: denyFolderValue) {
                        
                        action = denyFolder.action
                    }
                    else {
                        action = .junk
                    }
                }
            }
            
        case .denyLanguage:
            for filter in filters {
                if let text = filter.value(forKey: "text") as? String {
                    let language = NLLanguage(filterText: text)
                    
                    if language != .undetermined,
                       NLLanguage.dominantLanguage(for: body) == language {
                        
                        if let denyFolderValue = filter.value(forKey: "folderType") as? Int64,
                           let denyFolder = DenyFolderType(rawValue: denyFolderValue) {
                            
                            action = denyFolder.action
                        }
                        else {
                            action = .junk
                        }
                    }
                }
            }
        }

        return action
    }
    
    private func runAutomaticFilters(body: String, sender: String) -> ILMessageFilterAction {
        var action = ILMessageFilterAction.none
        let messageText = "\(sender) \(body)"
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        let cacheRequest: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        
        guard let automaticFiltersLanguageRecords = try? self.context.fetch(languageRequest),
              let cacheRow = try? self.context.fetch(cacheRequest).first,
              let filtersData = cacheRow.filtersData,
              let automaticFilterList = AutomaticFilterList(base64String: filtersData) else {
                  
                  self.logger?.error("ERROR! While loading cache on MessageEvaluationManager.runAutomaticFilters")
                  return action
              }
        
        for automaticFiltersLanguageRecord in automaticFiltersLanguageRecords {
            if automaticFiltersLanguageRecord.isActive,
               let langRawValue = automaticFiltersLanguageRecord.lang,
               let filterList = automaticFilterList.filterList[langRawValue] {
                
                for filter in filterList {
                    if messageText.contains(filter.lowercased()) {
                        action = .junk
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
                    if let _ = body.range(of: "http", options: .caseInsensitive) {
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
                    if self.isEmail(sender) {
                        action = .junk
                        break
                    }
                }
            }
        }
        
        return action
    }
    
    private func isEmail(_ candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
}
