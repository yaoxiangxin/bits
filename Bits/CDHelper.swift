//
//  CDHelper.swift
//  Bits
//
//  Created by Huanzhong Huang on 3/8/16.
//  Copyright © 2016 Huanzhong Huang. All rights reserved.
//

import CoreData

private let _sharedCDHelper = CDHelper()

class CDHelper: NSObject {

    // MARK: - SHARED INSTANCE
    class var shared: CDHelper {
        return _sharedCDHelper
    }
    
    // MARK: - PATHS
    lazy var storesDirectory: NSURL? = {
        let fm = NSFileManager.defaultManager()
        let urls = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.last // urls[urls.count - 1]
    }()
    
    lazy var localStoreURL: NSURL? = {
        if let url = self.storesDirectory?.URLByAppendingPathComponent("LocalStore.sqlite") {
            print("localStoreURL = \(url)")
            return url
        }
        return nil
    }()
    
    lazy var modelURL: NSURL = {
        let bundle = NSBundle.mainBundle()
        if let url = bundle.URLForResource("Model", withExtension: "momd") {
            return url
        }
        print("CRITICAL - Managed Object Model file not found")
        abort()
    }()
    
    // MARK: CONTEXT
    lazy var context: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.coordinator
        return moc
    }()
    
    // MARK: MODEL
    lazy var model: NSManagedObjectModel = {
        return NSManagedObjectModel(contentsOfURL: self.modelURL)!
    }()
    
    // MARK: COORDINATOR
    lazy var coordinator: NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel: self.model)
    }()
    
    // MARK: LOCALSTORE
    lazy var localStore: NSPersistentStore? = {
        let options: [NSObject: AnyObject] = [/*NSSQLitePragmasOption: ["journal_mode": "DELETE"],*/ NSMigratePersistentStoresAutomaticallyOption: 1, NSInferMappingModelAutomaticallyOption: 1]
        var _localStore: NSPersistentStore?
        do {
            _localStore = try self.coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.localStoreURL, options: options)
            return _localStore
        } catch {
            return nil
        }
    }()
    
    // MARK: - SETUP
    required override init() {
        super.init()
        self.setupCoreData()
    }
    
    func setupCoreData() {
        _ = self.localStore // creating this constant starts the chain of events that instantiates the Core Data Stack
    }
    
    // MARK: - SAVING
    class func save(moc: NSManagedObjectContext) {
        moc.performBlockAndWait {
            guard moc.hasChanges else {
                print("SKIPPED saving context \(moc.description) because there are no changes")
                return
            }
            do {
                try moc.save()
                print("SAVED context \(moc.description)")
            } catch {
                print("ERROR saving context \(moc.description) - \(error)")
            }
            if let parentContext = moc.parentContext {
                save(parentContext)
            }
        }
    }
    
    class func saveSharedContext() {
        save(shared.context)
    }

}
