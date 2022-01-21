//
//  PersistenceController.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import CoreData
import NaturalLanguage

struct PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        result.loadDebugData()
        return result
    }()
    static var getFiltersFetchRequest: NSFetchRequest<Filter> {
        let request: NSFetchRequest<Filter> = Filter.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Filter.type, ascending: false),
                                   NSSortDescriptor(keyPath: \Filter.text, ascending: true)]
        return request
    }
    static var frequentlyAskedQuestions = [Question(text: "faq_question_0"~, answer: "faq_answer_0"~, action: .activateFilters),
                                           Question(text: "faq_question_1"~, answer: "faq_answer_1"~),
                                           Question(text: "faq_question_2"~, answer: "faq_answer_2"~),
                                           Question(text: "faq_question_3"~, answer: "faq_answer_3"~),
                                           Question(text: "faq_question_4"~, answer: "faq_answer_4"~),
                                           Question(text: "faq_question_5"~, answer: "faq_answer_5"~)]
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
        self.container = container
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
    }
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType = .junk) {
        guard !self.isDuplicateFilter(text: text, type: type) else { return }
        
        let newFilter = Filter(context: self.container.viewContext)
        newFilter.uuid = UUID()
        newFilter.filterType = type
        newFilter.denyFolderType = denyFolder
        newFilter.text = text
        
        do {
            try self.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func isDuplicateFilter(text: String, type: FilterType) -> Bool {
        var filterExists = false
        let fetchRequest = NSFetchRequest<Filter>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld AND text == %@", type.rawValue, text)
        
        do {
            let results = try self.container.viewContext.fetch(fetchRequest)
            filterExists = results.count > 0
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return filterExists
    }
    
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        offsets.map({ filters[$0] }).forEach({ self.container.viewContext.delete($0) })
        
        do {
            try self.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func deleteFilters(_ filters: Set<Filter>) {
        filters.forEach({ self.container.viewContext.delete($0) })
        
        do {
            try self.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
        filter.denyFolderType = denyFolder
        
        do {
            try self.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func languages(for type: LanguageListViewType) -> [NLLanguage] {
        var supportedLanguages: [NLLanguage] = []
        
        switch type {
        case .blockLanguage:
            let remainingSupportedLanguages = NLLanguage.allSupportedCases
                .filter({ !self.isDuplicateFilter(text: $0.filterText, type: .denyLanguage) })
                .sorted(by: { $0.filterText < $1.filterText })
            supportedLanguages.append(contentsOf: remainingSupportedLanguages)
            
        case .automaticBlocking:
            supportedLanguages.append(.hebrew)
            supportedLanguages.append(.english)
        }

        return supportedLanguages
    }
    
    func loadDebugData() {
        struct AllowEntry {
            let text: String
            let folder: DenyFolderType
        }
        
        let _ = [AllowEntry(text: "נתניהו", folder: .junk),
                 AllowEntry(text: "הלוואה", folder: .junk),
                 AllowEntry(text: "הימור", folder: .junk),
                 AllowEntry(text: "גנץ", folder: .junk),
                 AllowEntry(text: "Weed", folder: .junk),
                 AllowEntry(text: "Bet", folder: .junk)].map { entry -> Filter in
            let newFilter = Filter(context: self.container.viewContext)
            newFilter.uuid = UUID()
            newFilter.filterType = .deny
            newFilter.denyFolderType = entry.folder
            newFilter.text = entry.text
            return newFilter
        }
        
        let _ = ["Adi", "דהאן", "דהן", "עדי"].map { allowText -> Filter in
            let newFilter = Filter(context: self.container.viewContext)
            newFilter.uuid = UUID()
            newFilter.filterType = .allow
            newFilter.text = allowText
            return newFilter
        }
        
        let langFilter = Filter(context: self.container.viewContext)
        langFilter.uuid = UUID()
        langFilter.filterType = .denyLanguage
        langFilter.text = NLLanguage.arabic.filterText
        
        do {
            try self.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
