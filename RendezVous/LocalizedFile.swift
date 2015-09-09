//
//  LocalizedFile.swift
//  RendezVous
//
//  Created by Pedro Gomes on 31/07/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
enum LocalizedPattern : String {
    case KeyValuePair  = "^\"(.+)\"\\s*=\\s*\"(.*)\";$"
    case CommentStart  = "^/\\*.*$"
    case CommentEnd    = "^.*\\*/$"
    case CommentBlock  = "^/\\*.*\\*/$"
    case EmptyLine     = "^\n+$"
    
    func expression() -> NSRegularExpression? {
        do {
            let expression = try NSRegularExpression(pattern: self.rawValue, options: NSRegularExpressionOptions.CaseInsensitive)
            return expression
        }
        catch {
            return nil
        }
    }
}

enum LocalizedFileError: ErrorType {
    case InvalidFile
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public struct LocalizedString: Equatable, Comparable {
    var key: String
    var value: String
    var comment: [String]

    init(key: String, value: String, comment: [String]) {
        self.key     = key
        self.value   = value
        self.comment = comment
    }

    init(keyValuePair: String, comment: [String]) {
        let groups = keyValuePair =~ LocalizedPattern.KeyValuePair.rawValue
        
        self.init(key: groups[1], value: groups[2], comment: comment)
    }
}

public func ==(lhs: LocalizedString, rhs: LocalizedString) -> Bool {
    return (lhs.key == rhs.key &&
        lhs.value == rhs.value &&
        lhs.comment == rhs.comment)
}

public func <(lhs: LocalizedString, rhs: LocalizedString) -> Bool {
    return lhs.key < rhs.key
}

public func <=(lhs: LocalizedString, rhs: LocalizedString) -> Bool {
    return lhs.key <= rhs.key
}

public func >=(lhs: LocalizedString, rhs: LocalizedString) -> Bool {
    return lhs.key >= rhs.key
}

public func >(lhs: LocalizedString, rhs: LocalizedString) -> Bool {
    return lhs.key > rhs.key
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public struct LocalizedFile {
    let path: String
    let name: String
    var strings: [LocalizedString]
    
    private var loaded: Bool = false
    
    private var stringsByKey: [String: LocalizedString]
    
    public init(path: String) {
        self.path         = path
        self.name         = (path as NSString).lastPathComponent
        self.strings      = []
        self.stringsByKey = [String: LocalizedString]()
    }
    
    public init(url: NSURL) {
        self.path         = url.absoluteString
        self.name         = (path as NSString).lastPathComponent
        self.strings      = []
        self.stringsByKey = [String: LocalizedString]()
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public mutating func read() throws -> Bool {
        guard self.loaded == false else { return true }
        
        let reader = LineByLineFileReader(path: self.path)
        var line   = reader.readLine()
        
        while (line != nil) {
            var comments = [line!]
            var translation: String?
            
            if line! !~ LocalizedPattern.CommentBlock.rawValue {
                line = reader.readLine()
                while (line != nil) && (line! =~ LocalizedPattern.CommentEnd.rawValue) {
                    comments.append(line!)
                    line = reader.readLine()
                }
            }
            else {
                line = reader.readLine()

                while (line != nil) && ((line! =~ "") || (line! == "\n")) {
                    line = reader.readLine()
                }
            }

            if (line != nil) && (line! =~ LocalizedPattern.KeyValuePair.rawValue) {
                translation = line!
            }
            
            line = reader.readLine()
            while (line != nil) && ((line! =~ "") || (line! == "\n")) {
                line = reader.readLine()
            }
            
            if translation != nil {
                self.add(LocalizedString(keyValuePair: translation!, comment: comments))
            }
            else {
                
            }
        }
        
        self.loaded = true
        
        return true
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public mutating func add(string: LocalizedString) {
        self.removeKey(string.key)
        self.stringsByKey[string.key] = string
        self.strings.append(string)
        sort()
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public mutating func add(key: String, value: String, comment: String) {
        let comments = comment.componentsSeparatedByString("\n")
        let string   = LocalizedString(keyValuePair: "\(key) = \(value)", comment: comments)
        
        add(string)
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public mutating func removeKey(key: String) {
        guard self.stringsByKey[key] != nil else { return }
        
        if let indexToRemove = self.strings.indexOf({ item -> Bool in
            return item.key == key
        }) {
            self.strings.removeAtIndex(indexToRemove)
        }
        self.stringsByKey[key] = nil
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func containsKey(key: String) -> Bool {
        return self.stringsByKey[key] != nil
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func allKeys() -> Set<String> {
        return Set(self.stringsByKey.keys)
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func toString() -> String {
        var lines = [String]()
        
        for line in self.strings {
            lines.append((line.comment as NSArray).componentsJoinedByString("\n"))
            lines.append("\"\(line.key)\" = \"\(line.value)\";\n")
            lines.append("\n")
        }
        return (lines as NSArray).componentsJoinedByString("")
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public subscript(key: String) -> LocalizedString? {
        return self.stringsByKey[key]
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    private mutating func sort() {
        self.strings.sortInPlace { $0 <= $1 }
    }
}