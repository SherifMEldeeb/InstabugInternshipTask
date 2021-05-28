//
//  SharedCoreData.swift
//  InstabugLogger
//
//  Created by Sherif M. Eldeeb on 5/27/21.
//  Copyright © 2021 Sherif M. Eldeeb. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataClientProtocol {
    func save() throws
    func count<T>(object: T.Type, completion handler: @escaping (Int) -> Void) throws where T: NSManagedObject
    /// An object getter that excute Asynchronously on a bg thread
    ///
    /// - Parameters:
    ///   - object: The NSManagedObject model to retrieve.
    ///   - descriptorKey: A key that is used to order the records.
    ///   - predicate: A filter to the fetched records.
    ///   - completion: A completion handler that is called with a list of fetched records or nil
    ///                 if any error occured.
    func get<T>(object: T.Type, descriptorKey: String?, predicate: NSPredicate?, completion: @escaping ([T]?) -> Void) where T: NSManagedObject
//    func delete<T>(object: T) where T: NSManagedObject
    func deleteAll<T>(object: T.Type, completion handler: @escaping (Error?) -> Void) where T: NSManagedObject
    func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void)
    var viewContext: NSManagedObjectContext { get }
}

class CoreDataClient: CoreDataClientProtocol {
    private let bgMode: Bool
    private let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    static let shared: CoreDataClientProtocol = CoreDataClient(modelName: "InstabugLogger", activateBGContext: true)
    
    private init(modelName: String, activateBGContext isBG: Bool) {
        persistentContainer = NSPersistentContainer(name: modelName)
        self.bgMode = isBG
        loadStore()
    }
    // MARK: Private Methods
    private func loadStore(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (describtion, err) in
            guard err == nil  else { fatalError(err!.localizedDescription) }
            completion?()
        }
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        if (bgMode) {
            viewContext.automaticallyMergesChangesFromParent = true
        }
    }
    
    private func get<T>(request fetchReq: NSFetchRequest<NSFetchRequestResult>) -> [T]? where T : NSManagedObject {
        if let result = try? persistentContainer.viewContext.fetch(fetchReq) {
            return result as? [T]
        }
        return nil
    }
    
    // MARK:- Protocol Methods
    func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    func count<T>(object: T.Type, completion handler: @escaping (Int) -> Void) throws where T : NSManagedObject {
        persistentContainer.performBackgroundTask {
            let fetchReq = object.fetchRequest()
            do {
                handler(try $0.count(for: fetchReq))
            }catch {
                handler(-1)
            }
        }
    }
    
    
    func save() throws {
        if bgMode {
            persistentContainer.performBackgroundTask {
                if $0.hasChanges {
                    do {
                        try $0.save()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }else {
            if persistentContainer.viewContext.hasChanges {
                do {
                    try persistentContainer.viewContext.save()
                } catch {
                    throw error
                }
            }
        }
    }
    
    func get<T>(object: T.Type, descriptorKey: String?, predicate: NSPredicate?, completion: @escaping ([T]?) -> Void) where T: NSManagedObject {
        let fetchReq: NSFetchRequest<NSFetchRequestResult> = object.fetchRequest()
        
        if let key = descriptorKey {
            let sortDescriptr = NSSortDescriptor(key: key, ascending: false)
            fetchReq.sortDescriptors = [sortDescriptr]
        }
        
        if let predic = predicate {
            fetchReq.predicate = predic
        }
        
        if (bgMode) {
            persistentContainer.performBackgroundTask {
                if let result = try? $0.fetch(fetchReq) {
                    completion(result as? [T])
                    return
                }
                completion(nil)
            }
        }else {
            completion(get(request: fetchReq))
        }
    }
    
//    func delete<T>(object: T) where T : NSManagedObject {
//        if bgMode {
//            persistentContainer.performBackgroundTask { $0.delete(object) }
//            return
//        }
//        persistentContainer.viewContext.delete(object)
//    }
//
    func deleteAll<T>(object: T.Type, completion handler: @escaping (Error?) -> Void) where T : NSManagedObject {
        if bgMode {
            persistentContainer.performBackgroundTask {
                do {
                    try $0.execute(NSBatchDeleteRequest(fetchRequest: InstabugLog.fetchRequest()))
                    handler(nil)
                }catch {
                    handler(error)
                }
            }
            return
        }
        do {
            try persistentContainer.viewContext.execute(NSBatchDeleteRequest(fetchRequest: InstabugLog.fetchRequest()))
            handler(nil)
        }catch {
            handler(error)
        }
        handler(nil)
    }

    
}
