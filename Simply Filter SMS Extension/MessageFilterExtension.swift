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

    func handle(_ queryRequest: ILMessageFilterQueryRequest, context: ILMessageFilterExtensionContext, completion: @escaping (ILMessageFilterQueryResponse) -> Void) {
        let offlineAction = self.offlineAction(for: queryRequest)
        let response = ILMessageFilterQueryResponse()
        response.action = offlineAction
        
        completion(response)
    }

    private func offlineAction(for queryRequest: ILMessageFilterQueryRequest) -> ILMessageFilterAction {
        guard let messageBody = queryRequest.messageBody?.lowercased() else { return .none }
        
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Filter")
        
        do {
            let filters = try managedContext.fetch(fetchRequest)
            
            let allowList = filters.filter({ guard let value = $0.value(forKey: "type") as? Int64,
                                                   Int(value) == FilterType.allow.rawValue else { return false }
                return true
            })
            
            for allowFilter in allowList {
                if let allowedText = allowFilter.value(forKey: "text") as? String,
                   messageBody.contains(allowedText.lowercased()) {
                    return .allow
                }
            }
            
            
            let denyList = filters.filter {
                guard let value = $0.value(forKey: "type") as? Int64,
                      Int(value) == FilterType.deny.rawValue else { return false }
                
                return true
            }
            
            for denyFilter in denyList {
                if let deniedText = denyFilter.value(forKey: "text") as? String,
                   messageBody.contains(deniedText.lowercased()) {
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
