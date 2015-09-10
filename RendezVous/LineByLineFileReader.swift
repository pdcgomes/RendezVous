//
//  LineByLineFileReader.swift
//  RendezVous
//
//  Created by Pedro Gomes on 03/08/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
protocol FileReader {
    
    init(path: String, encoding: UInt);
    init(url: NSURL, encoding: UInt);
    
    func read() -> Void;
}

public extension NSData {
    func findRangeOfData(data: NSData) -> (Bool, NSRange) {
        
        var match = NSMakeRange(NSNotFound, 0)
        var range = self.rangeOfData(data, options: NSDataSearchOptions.Backwards, range: NSRange(location: 0, length: self.length))
        
        while range.location != NSNotFound {
            match = range
            
            range = self.rangeOfData(data, options: NSDataSearchOptions.Backwards, range: NSRange(location: 0, length: match.location))
        }
        
        return (match.location != NSNotFound, match)
        
    }
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
final class LineByLineFileReader: FileReader {
    var path: String
    var delimiter: String
    var chunkSize: Int
    
    var fileHandle: NSFileHandle
    var fileLength: UInt64
    var readOffset: UInt64
    
    var encoding: UInt
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    deinit {
        self.fileHandle.closeFile()
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    init(path: String, encoding: UInt) {
        self.path       = path
        self.encoding   = encoding
        
        self.delimiter  = "\n"
        self.chunkSize  = 16
        self.readOffset = 0
        
        self.fileHandle = NSFileHandle(forReadingAtPath: self.path)!
        self.fileHandle.seekToEndOfFile()
        self.fileLength = self.fileHandle.offsetInFile ?? 0
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    convenience init(url: NSURL, encoding: UInt) {
        self.init(path: url.absoluteString, encoding: encoding)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    convenience init(path: String, delimiter: String, encoding: UInt) {
        self.init(path: path, encoding: encoding)
        self.delimiter = delimiter
    }
    
    func read() {
        
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func readLine() -> String? {
        guard self.readOffset < self.fileLength else { return nil }
        
        let separator = self.delimiter.dataUsingEncoding(self.encoding)!
        let readData  = NSMutableData()
        var readNext  = true
        
        self.fileHandle.seekToFileOffset(self.readOffset)
        
        while readNext {
            guard self.readOffset < self.fileLength else { break }
            
            var chunk = self.fileHandle.readDataOfLength(self.chunkSize)
            
            let (wasFound, atRange) = chunk.findRangeOfData(separator)
            
            if wasFound {
                chunk = chunk.subdataWithRange(NSRange(location: 0, length: atRange.location + atRange.length))
                readNext = false
            }
            readData.appendData(chunk)
            
//            print(NSString(data: readData, encoding: NSUTF8StringEncoding))
            readOffset = UInt64(Double(readOffset) + Double(chunk.length))
        }
        
        
        if let line = NSString(data: readData, encoding: self.encoding) {
            return line as String
        }
        return nil
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func enumerateLinesUsingBlock(block: (String, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)
        
        while stop.boolValue == false {
            if let line = self.readLine() {
                block(line as String, &stop)
            }
        }
    }
    
}
