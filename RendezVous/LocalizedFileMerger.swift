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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
func checkIfIsStringsFile(file: NSURL) -> Bool {
    do {
        let fileWrapper = try NSFileWrapper(URL:file, options: [])
        return fileWrapper.directory == false && file.pathExtension == "strings"
    }
    catch {
        return false
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
func findAndMerge(pathForGeneratedStrings: String, pathForTranslatedStrings: String) {
    
    guard checkDirectoryExists(pathForGeneratedStrings) &&
          checkDirectoryExists(pathForTranslatedStrings)
    else {
        return
    }

    var generated   = findStringsFilesAtPath(pathForGeneratedStrings)
    let langFolders = findLanguageFoldersAtPath(pathForTranslatedStrings)

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func reloadLanguageFiles() -> ([LocalizedFile], Dictionary<String, [LocalizedFile]>) {
        var translationFileList           = [LocalizedFile]()
        var translationFileListByLanguage = Dictionary<String, [LocalizedFile]>();

        for folder in langFolders {
            let files = findStringsFilesAtPath(folder)
            
            translationFileListByLanguage[folder] = files
            translationFileList += files
        }
        return (translationFileList, translationFileListByLanguage)
    }
    
    let (translationFileList, translationFileListByFolder) = reloadLanguageFiles()
    
    ////////////////////////////////////////////////////////////////////////////////
    // 1) Copy missing files
    ////////////////////////////////////////////////////////////////////////////////
    func extractPaths(files: [LocalizedFile]) -> Set<String> {
        return Set(files.map({ (file) -> String in
            return file.path.lastPathComponent
        }))
    }

    let fileManager      = NSFileManager.defaultManager()
    let fromFiles        = extractPaths(generated)
    var createdFileCount = 0
    
    for (folder, files) in translationFileListByFolder {
        let existing = extractPaths(files)
        let filesToCreateList  = fromFiles.subtract(existing)
        
        createdFileCount += filesToCreateList.count
        
        for file in filesToCreateList {
            let nameAndExtension = file.lastPathComponent
            let createAtPath = folder.stringByAppendingPathComponent(nameAndExtension)
            let copyFromPath = pathForGeneratedStrings.stringByAppendingPathComponent(nameAndExtension)

            do {
                try fileManager.copyItemAtPath(copyFromPath, toPath: createAtPath)
                print("--> created \(createAtPath) ...")
            }
            catch {}
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    for i in 0..<generated.count {
        do {
            var file = generated[i]
            
            try file.read()
            
            var mergeWithFiles = [LocalizedFile]()
            
            for (_, files) in translationFileListByFolder {
                let matches = files.filter({ (translatedFile: LocalizedFile) -> Bool in
                    return translatedFile.name == file.name
                })
                
                for match in matches {
                    mergeWithFiles.append(match)
                }
            }

            for n in 0..<mergeWithFiles.count {
                try mergeWithFiles[n].read()
                doMergeFile(file, withFile: mergeWithFiles[n])
            }
        }
        catch {
            
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
func doMergeFile(file: LocalizedFile, withFile: LocalizedFile) {
    
    let fromKeys = file.allKeys()
    let toKeys   = withFile.allKeys()

    var copy = withFile

    let deletedKeys = toKeys.subtract(fromKeys)
    var shouldSave  = deletedKeys.count > 0
    
    for key in deletedKeys {
        copy.removeKey(key)
    }
    
    for key in fromKeys {
        let line = file[key]!
        
        if let translatedLine = copy[key] {
            if translatedLine == line {
                continue
            }
            shouldSave = true
            copy.add(LocalizedString(key: translatedLine.key, value: translatedLine.value, comment: line.comment))
        }
        else {
            shouldSave = true
            copy.add(LocalizedString(key: line.key, value: line.value, comment: line.comment))
        }
    }
    
    guard shouldSave == true else { return }

    print("--> updated \(withFile.path) ...")

    if let unicode = copy.toString().dataUsingEncoding(NSUTF8StringEncoding) {
        unicode.writeToFile(withFile.path, atomically: true)
    }
    
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
func findStringsFilesAtPath(path: String) -> [LocalizedFile] {
    var files: [LocalizedFile] = []
    
    let fileManager = NSFileManager.defaultManager()
    let enumerator = fileManager.enumeratorAtURL(
        NSURL.fileURLWithPath(path, isDirectory: true),
        includingPropertiesForKeys: [NSURLIsRegularFileKey, NSURLIsReadableKey],
        options: []) { (url, error) -> Bool in
            return false
    }

    if enumerator == nil { return [] }

    for file in enumerator! {
        if checkIfIsStringsFile(file as! NSURL) {
            files.append(LocalizedFile(path: file.path))
        }
    }
    
    return files
}


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
func findLanguageFoldersAtPath(path: String) -> [String] {
    do {
        let fileManager = NSFileManager.defaultManager()
        let folders     = try fileManager.contentsOfDirectoryAtURL(NSURL(string: path)!, includingPropertiesForKeys: [NSURLIsDirectoryKey], options: [])
        
        var paths = [String]()
        
        for folder in folders {
            if let path = folder.path {
                let isLanguageFolder = (path as NSString).lastPathComponent.hasSuffix(".lproj")
                if isLanguageFolder {
                    paths.append(path)
                }
            }
        }
        return paths
    }
    catch {
        return []
    }
}