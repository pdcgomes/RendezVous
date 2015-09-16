//
//  cli.swift
//  RendezVous
//
//  Created by Pedro Gomes on 03/08/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public class CommandLineParser {

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func runWithArguments(arguments: [String]) -> Bool {
        
        guard validateArguments(arguments) else { return false }
        
        return true
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func printUsage() {
        let doc : String =
            "RendezVous, a simple .strings merger by Pedro Gomes (c) 2015\n" +
            "\n" +
            "Usage:\n" +
            "   rendezvous [OPTIONS] <generated_dir> <translations_dir>\n" +
            "\n" +
            "Examples:\n" +
            "   rendezvous --reporter json ~/Projects/MyProject/GeneratedStrings ~/Projects/MyProject/Translations\n" +
            "\n" +
            "Options:\n" +
            "   -r, --reporter TYPE\n\n" +
            "Reporters:\n" +
            "   json\n" +
            "   pretty (default)\n"
        print(doc)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    private func validateArguments(arguments: [String]) -> Bool {
        guard arguments.count == 2 else { return false }
        
        let tracker = ChangeTracker()
        let merger = LocalizedFileMerger(tracker: tracker)
        
        guard merger.checkDirectoryExists(arguments[0]) else { return false }
        guard merger.checkDirectoryExists(arguments[1]) else { return false }
        
        let result = merger.findAndMerge(arguments[0], pathForTranslatedStrings: arguments[1])
        
        if result {
            let reporter = ChangeReportStandardOutputRenderer()
//            let reporter = ChangeReportJSONRender()
            reporter.render(tracker.changes, errors: tracker.errors)
        }
        
        return true
    }
}