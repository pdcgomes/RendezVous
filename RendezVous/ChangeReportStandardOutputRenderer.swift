//
//  StandardOutputChangeReportRenderer.swift
//  RendezVous
//
//  Created by Pedro Gomes on 15/09/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public enum ChangeReportOutputStyle {
    case Default;
    case Colorized;
}

typealias ColorizeFunction = (String, AnsiColorCode, AnsiColorCode -> String)
typealias Color = ColorizeFunction -> ColorizeFunction

//func colorize(string: String, foreground: AnsiColorCode = .Default, background: AnsiColorCode = .Default) -> ColorizeFunction {
//    return {
//        a: string, f: foreground,
//        b: background in {
//            string.colorize(foreground, background: background, mode: .Default)
//        }
//    }
//
////    return func(string: String, foreground: AnsiColorCode = .Default, background: AnsiColorCode = .Default) -> String {
////        return string.colorize(foreground, background: background, mode: .Default)
////    }
//}
//

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
struct ChangeReportStandardOutputRenderer : ChangeReportRenderer {
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func render(changes: [String : [Change]], errors: [String: ErrorType]? = nil, groupBy: ChangeReportGroupingStyle = .NoGrouping) {
        
        render(changes, errors: errors, groupBy: groupBy, style: .Default)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func render(changes: [String : [Change]], errors: [String: ErrorType]? = nil, groupBy: ChangeReportGroupingStyle = .NoGrouping, style: ChangeReportOutputStyle) {
        
        var renderFunction: ([String: [Change]] -> Void)
        
        switch (groupBy, style) {
            case (.NoGrouping, .Default):           renderFunction = renderNoGrouping
            case (.NoGrouping, .Colorized):         renderFunction = renderNoGroupingColorized
            case (.GroupByChangeType, .Default):    renderFunction = renderGroupByChangeType
            case (.GroupByChangeType, .Colorized):  renderFunction = renderGroupByChangeTypeColorized
        }
        
        renderFunction(changes)
        
        if errors != nil {
            renderErrors(errors!)
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    private func renderErrors(errors: [String: ErrorType]) {
        for (file, error) in errors {
            print("--> error: \(file), \(error)")
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    private func renderNoGrouping(changes: [String: [Change]]) {
        for (file, changeList) in changes {
            print("--> updated \(file) ...")
            
            for change in changeList {
                print("  --> \(change.type): \(change.key)")
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    private func renderNoGroupingColorized(changes: [String: [Change]]) {
        for (file, changeList) in changes {
            print("--> updated " + file.green.bold + " ...")
            
            for change in changeList {
                print("  --> " + "\(change.type)".white.bold + ": " + change.key.green.bold)
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    private func renderGroupByChangeType(changes: [String: [Change]]) {
        
        ////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////
        func extractChangesByType(type: Change.ChangeType, changeList: [Change]) -> [Change] {
            return changeList.filter { $0.type == type }
        }
        
        ////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////
        func reportChanges(kind: String, changeList: [Change]) {
            guard changeList.count > 0 else { return }
            
            print("  --> \(kind):")
            
            for change in changeList {
                print("  --> \(change.type): \(change.key)")
            }
        }
        
        ////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////
        for (file, changeList) in changes {
            let createdList = extractChangesByType(.Created, changeList: changeList)
            let deletedList = extractChangesByType(.Deleted, changeList: changeList)
            let updatedList = extractChangesByType(.Changed, changeList: changeList)
            let changeCount = (createdList.count + deletedList.count + updatedList.count)
            
            guard changeCount > 0 else { continue }
            
            print("--> updated \(file) ...")
            
            reportChanges("created", changeList: createdList)
            reportChanges("updated", changeList: updatedList)
            reportChanges("deleted", changeList: deletedList)
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    private func renderGroupByChangeTypeColorized(changes: [String: [Change]]) {

    }
}
