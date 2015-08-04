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
        
    }
    
    private func validateArguments(arguments: [String]) -> Bool {
        return true
    }
}