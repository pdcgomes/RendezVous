//
//  FileEncodingDetector.swift
//  RendezVous
//
//  Created by Pedro Gomes on 10/09/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public enum FileEncoding : String {
    case ASCII             = "ASCII"
    case Unicode           = "Unicode"
    case UTF8              = "UTF-8"
    case UTF16             = "UTF-16"
    case UTF16BigEndian    = "UTF-16 Big Endian"
    case UTF16LittleEndian = "UTF-16 Little Endian"
    case Unknown           = "Unknown"
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
final class FileEncodingDetector {

    var encodingLookup: [String: FileEncoding]
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    init() {
        self.encodingLookup = [
            "ASCII":                .ASCII,
            "Big-endian UTF-16":    .UTF16BigEndian,
            "Little-endian UTF-16": .UTF16LittleEndian,
            "UTF-8":                .UTF8
        ]
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func detectEncodingForFileAtPath(path path: String) -> FileEncoding {
        let task = NSTask()
        task.launchPath = "/usr/bin/file"
        task.arguments  = [path]

        let pipe = NSPipe()
        task.standardOutput = pipe

        var encoding = FileEncoding.Unknown
        
        ////////////////////////////////////////////////////////////////////////////////
        // Parse Output function
        ////////////////////////////////////////////////////////////////////////////////
        NSNotificationCenter.defaultCenter().addObserverForName(
            NSFileHandleReadToEndOfFileCompletionNotification,
            object: pipe.fileHandleForReading,
            queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
                let key = NSFileHandleNotificationDataItem as NSString
                if let taskOutput = notification.userInfo?[key] as? NSData {
                    encoding = self.parseOutput(taskOutput)
                }
        }
        
        pipe.fileHandleForReading.readToEndOfFileInBackgroundAndNotify()
        task.launch()
        task.waitUntilExit()
        
        return encoding
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    private func parseOutput(data: NSData) -> FileEncoding {
        if let str  = NSString(data: data, encoding: NSASCIIStringEncoding) {
            for (pattern, encoding) in self.encodingLookup {
                if str.containsString(pattern as String) {
                    return encoding
                }
            }
        }
        return .Unknown
    }
}