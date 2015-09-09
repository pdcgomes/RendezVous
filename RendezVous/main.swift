//
//  main.swift
//  RendezVous
//
//  Created by Pedro Gomes on 31/07/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

//let path1 = "/Users/pedrogomes/Dropbox/Projects/RendezVous/Resources/Generated-Additions"
//let path2 = "/Users/pedrogomes/Dropbox/Projects/RendezVous/Resources/Translated"

var args = Process.arguments
args.removeAtIndex(0) // arguments[0] is always the program_name

let parser  = CommandLineParser()

if parser.runWithArguments(args) == false {
    parser.printUsage()
}
