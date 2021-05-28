//
//  LogLocalRepo.swift
//  InstabugLogger
//
//  Created by Sherif Eldeeb on 28/05/2021.
//

import Foundation

protocol LogLocalRepoProtocol {
    func getAllLogs(completion: @escaping ([InstabugLog]) -> Void)
    func getlog(_ id: Int, completion: @escaping (InstabugLog?) -> Void)
//    func delete(logs: [InstabugLog]) throws
    func countAllLogs(completion handler: @escaping (Int)-> Void)
    func save(_ id: Int, level: Int, message: String, timestamp: TimeInterval, completion handler: ((InstabugLog)-> Void)?) throws
    func clearLogs(completion handler: @escaping (Error?) -> Void)
}

class LogLocalRepo: LogLocalRepoProtocol {
    private let dbClient: CoreDataClientProtocol
    
    init(databaseClient: CoreDataClientProtocol) {
        self.dbClient = databaseClient
    }
    
    func getAllLogs(completion: @escaping ([InstabugLog]) -> Void) {
        dbClient.get(object: InstabugLog.self, descriptorKey: "timestamp", predicate: nil) {
            if let records = $0 {
                completion(records)
            }else {
                completion([])
            }
        }
    }
    
    func getlog(_ id: Int, completion: @escaping (InstabugLog?) -> Void) {
        dbClient.get(object: InstabugLog.self, descriptorKey: "id", predicate: NSPredicate(format: "id == %@", id)) {
            if let record = $0?.first {
                completion(record)
            }
            completion(nil)
        }
    }
    
//    func delete(logs: [InstabugLog]) throws {
//        for log in logs {
//            dbClient.delete(object: log)
//        }
//        do {
//            try dbClient.save()
//        }catch {
//            throw error
//        }
//    }
    
    func save(_ id: Int, level: Int, message: String, timestamp: TimeInterval, completion handler: ((InstabugLog)-> Void)? = nil) throws {
        var newLog: InstabugLog?
        let grp = DispatchGroup()
        grp.enter()
        dbClient.performBackgroundTask {
            newLog = InstabugLog(context: $0)
            newLog?.id = Int16(id)
            newLog?.level = NSNumber(value: level)
            newLog?.message = message
            newLog?.timestamp = timestamp
            grp.leave()
        }
        grp.wait()
        
        do {
            if let m = newLog {
                try dbClient.save()
                handler?(m)
            }else {
                throw NSError()
            }
        }catch {
            throw error
        }
    }
    
    func countAllLogs(completion handler: @escaping (Int)-> Void) {
        do {
            try self.dbClient.count(object: InstabugLog.self, completion: handler)
        }catch {
            debugPrint("LogLocalRepo -> Counting Logs Failed")
            handler(-1)
        }
    }
    
    func clearLogs(completion handler: @escaping (Error?) -> Void) {
        dbClient.deleteAll(object: InstabugLog.self, completion: handler)
    }

}
