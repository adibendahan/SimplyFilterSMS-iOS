//
//  AppPersistentCloudKitContainer.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 27/12/2021.
//

import CoreData

class AppPersistentCloudKitContainer: NSPersistentCloudKitContainer, @unchecked Sendable  {
    // All containers in a process share the model, avoiding ambiguous entity
    // class registration when independent readers are repeatedly opened.
    private static let sharedModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: AppPersistentCloudKitContainer.self)])!

    convenience init(name: String) {
        self.init(name: name, managedObjectModel: Self.sharedModel)
    }

    override class func defaultDirectoryURL() -> URL {
        guard let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupContainer) else {
            // Sentinel only; loadPersistentStores rejects this configuration.
            return URL(fileURLWithPath: "/unavailable-app-group")
        }
        
        return storeURL.appendingPathComponent(kDatabaseFilename)
    }
    
    static func sharedStoreURL() throws -> URL {
        guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupContainer) else {
            throw NSError(domain: "AppGroupConfiguration", code: 1)
        }
        return directory.appendingPathComponent(kDatabaseFilename).appendingPathComponent("\(kAppWorkingDirectory).sqlite")
    }

    override func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
        if let description = persistentStoreDescriptions.first,
           description.url?.path.hasPrefix("/unavailable-app-group") == true {
            block(description, NSError(domain: "AppGroupConfiguration", code: 1))
            return
        }
        super.loadPersistentStores(completionHandler: block)
    }

    convenience init(name: String, isReadOnly: Bool) {
        self.init(name: name)

        if isReadOnly {
            let description = NSPersistentStoreDescription()
            description.url = AppPersistentCloudKitContainer.defaultDirectoryURL().appendingPathComponent("\(name).sqlite")
            description.isReadOnly = isReadOnly
            self.persistentStoreDescriptions = [description]
        }
    }
}
