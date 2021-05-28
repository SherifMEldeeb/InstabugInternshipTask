//
//  InstabugLogger.swift
//  InstabugLogger
//
//  Created by Yosef Hamza on 19/04/2021.
//

import Foundation

public class InstabugLogger {
    public static var shared = InstabugLogger(store: LogLocalRepo(databaseClient: CoreDataClient.shared))
    
    public enum LogLevel: Int {
        case debug, error
    }
    
    private let store: LogLocalRepoProtocol
    private let messageLimit: Int = 1000
    private let recordsLimit: Int = 1000
    
    private init(store: LogLocalRepoProtocol) {
        self.store = store
    }

    // MARK: Logging
    public func log(_ level: LogLevel, message: String) {
        let rec: String = (message.count > messageLimit) ? (message.prefix(messageLimit) + "...") : message
        
        store.countAllLogs { [weak self] (count: Int) in
            guard let self = self else {  return  }
            if (count > self.recordsLimit) {
                try? self.store.save(count % self.recordsLimit, level: level.rawValue, message: rec, timestamp: Date().timeIntervalSince1970, completion: nil)
            }
        }
    }

    // MARK: Fetch logs
    public func fetchAllLogs(completion handler: @escaping ([InstabugLog])->Void) {
//        store.getAllLogs(completion: handler)
        self.store.countAllLogs {
            if $0 > 0 {
                debugPrint($0)
            }else {
                debugPrint("Some Error Occured")
            }
        }
    }
    
    public func clearLogs() {
        self.store.clearLogs {
            if let _ = $0 {
                return
            }
            debugPrint("Clear Done")
        }
    }
}
