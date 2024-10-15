//
//  AppPersistentCloudKitContainer.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 27/12/2021.
//

import CoreData

class AppPersistentCloudKitContainer: NSPersistentCloudKitContainer, @unchecked Sendable {
    override class func defaultDirectoryURL() -> URL {
        guard let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupContainer) else {
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
        
        return storeURL.appendingPathComponent(kDatabaseFilename)
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
