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

    public func runWithArguments(arguments: [String]) -> Bool {
        
        guard validateArguments(arguments) else { return false }
        
        return true
    }
    
    public func printUsage() {
        let doc : String = "RendezVous, a simple .strings merger by Pedro Gomes (c) 2015\n" +
            "\n" +
            "Usage:\n" +
            "  rendezvous <generated_dir> <translations_dir>\n" +
            "\n" +
            "Examples:\n" +
            "  rendezvous ~/Projects/MyProject/GeneratedStrings ~/Projects/MyProject/Translations\n"
        print(doc)
    }
    
    private func validateArguments(arguments: [String]) -> Bool {
        guard arguments.count == 2 else { return false }
        
        guard checkDirectoryExists(arguments[0]) else { return false }
        guard checkDirectoryExists(arguments[1]) else { return false }
        
        findAndMerge(arguments[0], pathForTranslatedStrings: arguments[1])
        
        return true
    }
}