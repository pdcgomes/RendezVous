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
    
    init(path: String);
    init(url: NSURL);
    
    func read() -> Void;
}

public extension NSData {
    func findRangeOfData(data: NSData) -> (Bool, NSRange) {
        
        let range = self.rangeOfData(data, options: NSDataSearchOptions.Backwards, range: NSRange(location: 0, length: self.length))
        
        return (range.location != NSNotFound, range)
        //        let bytes  = self.bytes
        //        let length = self.length
        //
        //        let searchBytes  = data.bytes
        //        let searchLength = data.length
        //
        //        let rangeSoFar  = NSRange(location: NSNotFound, length: 0)
        //        let searchIndex = 0
        //
        //        for var i = 0; i < length; i++ {
        //            if bytes[i] as UnsafeBufferPointer == searchBytes[searchIndex] {
        //
        //            }
        //        }
        //
        //        return (false, nil)
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
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    deinit {
        self.fileHandle.closeFile()
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    init(path: String) {
        self.path       = path
        
        self.delimiter  = "\n"
        self.chunkSize  = 16
        self.readOffset = 0
        
        self.fileHandle = NSFileHandle(forReadingAtPath: self.path)!
        self.fileHandle.seekToEndOfFile()
        self.fileLength = self.fileHandle.offsetInFile ?? 0
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    convenience init(url: NSURL) {
        self.init(path: url.absoluteString)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    convenience init(path: String, delimiter: String) {
        self.init(path: path)
        self.delimiter = delimiter
    }
    
    func read() {
        
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func readLine() -> String? {
        guard self.readOffset < self.fileLength else { return nil }
        
        let separator = self.delimiter.dataUsingEncoding(NSUTF8StringEncoding)!
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
            readOffset = UInt64(Double(readOffset) + Double(chunk.length))
        }
        
        
        if let line = NSString(data: readData, encoding: NSUTF8StringEncoding) {
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
