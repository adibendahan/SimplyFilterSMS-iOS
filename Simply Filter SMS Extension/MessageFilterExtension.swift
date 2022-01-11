//
//  MessageFilterExtension.swift
//  Simply Filter SMS Extension
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import IdentityLookup
import CoreData

final class MessageFilterExtension: ILMessageFilterExtension {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
        
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
                if let deniedLanguageText = denyLanguageFilter.value(forKey: "text") as? String,
                   let deniedLanguage = FilteredLanguage(rawValue: deniedLanguageText),
                   deniedLanguage != .unknown,
                   messageText.rangeOfCharacter(from: deniedLanguage.charcterSet) != nil {
                    return .junk
                }
            }
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return .none
        }
        
        return .allow
    }
}
