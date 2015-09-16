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
class LocalizedFileMerger {

    let tracker: ChangeTracker

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    init(tracker: ChangeTracker) {
        self.tracker = tracker
    }
    
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
    func findAndMerge(pathForGeneratedStrings: String, pathForTranslatedStrings: String) -> Bool {
        
        guard checkDirectoryExists(pathForGeneratedStrings) &&
            checkDirectoryExists(pathForTranslatedStrings)
            else {
                return false
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
                return file.name
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
                let nameAndExtension = (file as NSString).lastPathComponent
                let createAtPath = (folder as NSString).stringByAppendingPathComponent(nameAndExtension)
                let copyFromPath = (pathForGeneratedStrings as NSString).stringByAppendingPathComponent(nameAndExtension)
                
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
                print("Oops, something went wrong")
            }
        }
        return true
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func doMergeFile(file: LocalizedFile, withFile: LocalizedFile) -> Bool {
        
        let fromKeys = file.allKeys()
        let toKeys   = withFile.allKeys()
        
        var copy = withFile
        
        let deletedKeys = toKeys.subtract(fromKeys)
        var shouldSave  = deletedKeys.count > 0
        
        for key in deletedKeys {
            copy.removeKey(key)
            tracker.trackChange(file.path, change: Change(type: .Deleted, key: key))
        }
        
        var createdKeys: [String] = []
        var updatedKeys: [String] = []
        
        for fromKey in fromKeys {
            let line = file[fromKey]!
            
            if let translatedLine = copy[fromKey] {
                // The key already existed, so we check for comment updates
                if translatedLine.comment != line.comment {
                    shouldSave = true
                    copy.add(LocalizedString(key: translatedLine.key, value: translatedLine.value, comment: line.comment))
                    updatedKeys.append(translatedLine.key)
                    
                    tracker.trackChange(file.path, change: Change(
                        type: .Changed,
                        key: line.key,
                        newValue: line.comment.joinWithSeparator("")))
                }
            }
            else {
                shouldSave = true
                copy.add(LocalizedString(key: line.key, value: line.value, comment: line.comment))
                createdKeys.append(line.key)
                tracker.trackChange(
                    file.path,
                    change: Change(type: .Created, key: line.key, newValue: line.value))
            }
        }
        
        guard shouldSave == true else { return true }
        
        ////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////
        guard let unicode = copy.toString().dataUsingEncoding(copy.encoding.toStringEncoding()) else {
            tracker.trackError(withFile.path, error: NSError(domain: "", code: 1000, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Failed to encode file", comment: "")]))
            return false
        }
        
        let success = unicode.writeToFile(withFile.path, atomically: true)
        guard success == true else {
            tracker.trackError(withFile.path, error: NSError(domain: "", code: 1010, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Failed to save file", comment: "")]))
            return false
        }

        return true;
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func findStringsFilesAtPath(path: String) -> [LocalizedFile] {
        var files: [LocalizedFile] = []
        
        let fileManager = NSFileManager.defaultManager()
        let detector    = FileEncodingDetector()
        
        do {
            let contentsOfDirectory = try fileManager.contentsOfDirectoryAtURL(NSURL.fileURLWithPath(path, isDirectory: true), includingPropertiesForKeys: [NSURLIsRegularFileKey], options: [])
            
            for file in contentsOfDirectory {
                if checkIfIsStringsFile(file) {
                    let encoding = detector.detectEncodingForFileAtPath(path: file.path!)
                    files.append(LocalizedFile(path: file.path!, encoding: encoding))
                }
            }
        }
        catch {}
        
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
}
