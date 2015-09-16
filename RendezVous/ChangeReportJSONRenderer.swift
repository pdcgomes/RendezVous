//
//  ChangeReportJSONRenderer.swift
//  RendezVous
//
//  Created by Pedro Gomes on 16/09/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
class ChangeReportJSONRender : ChangeReportRenderer {
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func render(changes: [String : [Change]], errors: [String : ErrorType]?, groupBy: ChangeReportGroupingStyle = .GroupByChangeType) {
        
        var renderFunction: (([String: [Change]], [String: ErrorType]?) -> Void)
        
        switch groupBy {
            case .NoGrouping:           renderFunction = renderNoGrouping
            case .GroupByChangeType:    renderFunction = renderGroupByChangeType
        }
        
        renderFunction(changes, errors)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func renderNoGrouping(changes: [String: [Change]], errors: [String: ErrorType]?) {
        
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func renderGroupByChangeType(changes: [String: [Change]], errors: [String: ErrorType]?) {

        let fileList             = Array(changes.keys)
        var serializedChangeList = [[String: AnyObject]]()
        var serializedErrorList  = [[String: String]]()

        for (file, changeList) in changes {
            let changed = findChangesByType(.Changed, changes: changeList).map { $0.dictionaryValue }
            let created = findChangesByType(.Created, changes: changeList).map { $0.dictionaryValue }
            let deleted = findChangesByType(.Deleted, changes: changeList).map { $0.dictionaryValue }
            
            var dict = [String: AnyObject]()
            
            dict["file"] = file
            
            if changed.count > 0 { dict["changed"] = changed }
            if created.count > 0 { dict["created"] = created }
            if deleted.count > 0 { dict["deleted"] = deleted }
            
            serializedChangeList.append(dict)
        }
        
        if let errorList = errors {
            for (file, _) in errorList {
                serializedErrorList.append(["file": file, "error": ""])
            }
        }

        let report = [
            "files":    fileList,
            "changes":  serializedChangeList,
            "errors":   serializedErrorList
        ]
        
        do {
            let data   = try NSJSONSerialization.dataWithJSONObject(report, options: [.PrettyPrinted])
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                print(string)
            }
        }
        catch {}
    }
}
