//
//  PersistenceController.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        result.loadDebugData()
        return result
    }()
    
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        self.container = container
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
    }
    
    func loadDebugData() {
        struct AllowEntry {
            let text: String
            let folder: DenyFolderType
        }
        
        let _ = [AllowEntry(text: "נתניהו", folder: .promotion),
                 AllowEntry(text: "הלוואה", folder: .transaction),
                 AllowEntry(text: "הימור", folder: .junk),
                 AllowEntry(text: "גנץ", folder: .promotion)].map { entry -> Filter in
            let newFilter = Filter(context: container.viewContext)
            newFilter.uuid = UUID()
            newFilter.filterType = .deny
            newFilter.denyFolderType = entry.folder
            newFilter.text = entry.text
            return newFilter
        }
        
        let _ = ["Adi", "דהאן", "דהן", "עדי"].map { allowText -> Filter in
            let newFilter = Filter(context: container.viewContext)
            newFilter.uuid = UUID()
            newFilter.filterType = .allow
            newFilter.text = allowText
            return newFilter
        }
    
        let langFilter = Filter(context: container.viewContext)
        langFilter.uuid = UUID()
        langFilter.filterType = .denyLanguage
        langFilter.text = FilteredLanguage.arabic.rawValue
        
        do {
            try container.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
}
