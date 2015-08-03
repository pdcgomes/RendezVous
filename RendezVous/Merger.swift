//
//  Merger.swift
//  RendezVous
//
//  Created by Pedro Gomes on 31/07/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
func checkDirectoryExists(path: String) -> Bool {
    let fileManager = NSFileManager.defaultManager()
    var isDir       = ObjCBool(false)

    guard fileManager.fileExistsAtPath(path, isDirectory: &isDir) && isDir
    else {
        print("Invalid directory \(path)")
        return false
    }
    return true
}

func findAndMerge(pathForGeneratedStrings: String, pathForTranslatedStrings: String) {
    
    guard checkDirectoryExists(pathForGeneratedStrings) &&
          checkDirectoryExists(pathForTranslatedStrings)
    else {
        return
    }

    var generated  = loadStringsAtPath(pathForGeneratedStrings)
    var translated = loadStringsAtPath(pathForTranslatedStrings)

    for i in 0..<generated.count {
        var file = generated[i]
        
        do {
            try file.read()
        }
        catch {
            
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
func loadStringsAtPath(path: String) -> [LocalizedFile] {
    var files: [LocalizedFile] = []
    
    let fileManager = NSFileManager.defaultManager()
    let enumerator = fileManager.enumeratorAtURL(
        NSURL(string: path)!,
        includingPropertiesForKeys: [NSURLIsRegularFileKey, NSURLIsReadableKey],
        options: []) { (url, error) -> Bool in
            return false
    }

    if enumerator == nil { return [] }

    for file in enumerator! {
        do {
            let fileWrapper = try NSFileWrapper(URL:file as! NSURL, options: [])
            if fileWrapper.directory == false {
                files.append(LocalizedFile(path: file.path))
            }
        }
        catch {}
    }
    
    return files
}
