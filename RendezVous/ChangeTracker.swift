//
//  ChangeReporter.swift
//  RendezVous
//
//  Created by Pedro Gomes on 15/09/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public protocol DictionaryConvertible {
    var dictionaryValue: Dictionary<String, String> { get }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
extension Change : DictionaryConvertible {

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public var dictionaryValue: Dictionary<String, String> {
        var dict = ["key": key]
        
        switch type {
            case .Created: dict["newValue"] = newValue
            case .Changed:
                dict["oldValue"] = oldValue
                dict["newValue"] = newValue
            default: break
        }
        
        return dict
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public struct Change {
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public enum ChangeType : CustomStringConvertible {
        case Created;
        case Deleted;
        case Changed;
        
        ////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////
        public var description: String {
            switch self {
                case .Created: return "Created"
                case .Deleted: return "Deleted"
                case .Changed: return "Changed"
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    var type: ChangeType
    var key: String
    var oldValue: String
    var newValue: String
    
    init(type: ChangeType, key: String, oldValue: String = "", newValue: String = "") {
        self.type = type
        self.key = key
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public class ChangeTracker {
    var changes: [String: [Change]]
    var errors: [String: ErrorType]
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    init() {
        self.changes = [:]
        self.errors  = [:]
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func trackChange(file: String, change: Change) {
        if changes[file] == nil {
            changes[file] = []
        }
        changes[file]?.append(change)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func trackError(file: String, error: ErrorType) {
        changes.removeValueForKey(file)
        errors[file] = error
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func extractChangesByType(type: Change.ChangeType, changeList: [Change]) -> [Change] {
        return changeList.filter({ (change) -> Bool in
            return change.type == type
        })
    }
}