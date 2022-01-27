//
//  MessageFilterExtension.swift
//  Simply Filter SMS Extension
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import IdentityLookup
import CoreData
import NaturalLanguage

final class MessageFilterExtension: ILMessageFilterExtension {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory, isReadOnly: true)

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}

extension MessageFilterExtension: ILMessageFilterQueryHandling {
    
    func handle(_ queryRequest: ILMessageFilterQueryRequest,
                context: ILMessageFilterExtensionContext,
                completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        
        let offlineAction = self.offlineAction(for: queryRequest)
        let response = ILMessageFilterQueryResponse()
        
        response.action = offlineAction
        completion(response)
    }
    
    private func offlineAction(for queryRequest: ILMessageFilterQueryRequest) -> ILMessageFilterAction {
        let messageBody = queryRequest.messageBody?.lowercased() ?? ""
        let messageSender = queryRequest.sender?.lowercased() ?? ""
        let messageText = "\(messageSender) \(messageBody)"
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Filter")
        
        do {
            let filters = try managedContext.fetch(fetchRequest)
            
            //MARK: Priority #1 - Allow
            let allowList = filters.filter({ guard let value = $0.value(forKey: "type") as? Int64,
                                                   value == FilterType.allow.rawValue else { return false }
                return true
            })
            
            for allowFilter in allowList {
                if let allowedText = allowFilter.value(forKey: "text") as? String,
                   messageText.contains(allowedText.lowercased()) {
                    return .allow
                }
            }
            
            //MARK: Priority #2 - Deny
            let denyList = filters.filter {
                guard let value = $0.value(forKey: "type") as? Int64,
                      value == FilterType.deny.rawValue else { return false }
                
                return true
            }
            
            for denyFilter in denyList {
                if let deniedText = denyFilter.value(forKey: "text") as? String,
                   messageText.contains(deniedText.lowercased()) {
                    guard let denyFolderValue = denyFilter.value(forKey: "folderType") as? Int64,
                          let denyFolder = DenyFolderType(rawValue: denyFolderValue) else { return .junk }
                    
                    return denyFolder.action
                }
            }
            
            //MARK: Priority #3 - Deny Language
            let denyLanguageList = filters.filter {
                guard let value = $0.value(forKey: "type") as? Int64,
                      value == FilterType.denyLanguage.rawValue else { return false }
                
                return true
            }
            
            for denyLanguageFilter in denyLanguageList {
                if let deniedLanguageText = denyLanguageFilter.value(forKey: "text") as? String {
                    let deniedLanguage = NLLanguage(filterText: deniedLanguageText)
                    
                    if deniedLanguage != .undetermined,
                       NLLanguage.dominantLanguage(for: messageBody) == deniedLanguage {
                        guard let denyFolderValue = denyLanguageFilter.value(forKey: "folderType") as? Int64,
                              let denyFolder = DenyFolderType(rawValue: denyFolderValue) else { return .junk }
                        
                        return denyFolder.action
                    }
                }
            }
            
                //MARK: Priority #4 - Automatic Filtering
            return self.runAutomaticFilters(messageText: messageText)
        }
        catch let error as NSError {
            print("ERROR: Could not fetch. \(error), \(error.userInfo)")
            return .none
        }
    }
    
    func runAutomaticFilters(messageText: String) -> ILMessageFilterAction {
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        let cacheRequest: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        
        guard let automaticFiltersLanguages = try? self.persistentContainer.viewContext.fetch(languageRequest),
              let cacheRow = try? self.persistentContainer.viewContext.fetch(cacheRequest).first,
              let filtersData = cacheRow.filtersData,
              let automaticFilterList = AutomaticFilterList(base64String: filtersData) else {
                  
                  print("ERROR: error while loading cache")
                  return .none
              }
        
        for automaticFiltersLanguage in automaticFiltersLanguages {
            if automaticFiltersLanguage.isActive,
               let langRawValue = automaticFiltersLanguage.lang,
               let filterList = automaticFilterList.filterList[langRawValue] {
                
                for filter in filterList {
                    if messageText.contains(filter.lowercased()) {
                        return .junk
                    }
                }
            }
        }
        
        return .allow
    }
}
