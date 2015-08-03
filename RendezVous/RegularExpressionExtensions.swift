//
//  RegularExpressionExtensions.swift
//  RendezVous
//
//  Created by Pedro Gomes on 03/08/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
extension NSRegularExpression {
    func matches(string: String) -> Bool {
        return self.numberOfMatchesInString(string, options: NSMatchingOptions.Anchored, range: NSRange(location: 0, length: string.characters.count)) > 0
    }
}

////////////////////////////////////////////////////////////////////////////////
// Regular expression matching convenience operators
////////////////////////////////////////////////////////////////////////////////
struct RegularExpressionCaptureGroupGenerator: GeneratorType {
    var items: ArraySlice<String>
    
    mutating func next() -> String? {
        guard items.count > 0 else { return nil }
        
        let ret = items[0]
        items = items[1..<items.count]
        return ret
    }
}

struct RegularExpressionMatchResult: SequenceType, BooleanType {
    var items: Array<String>
    
    var boolValue: Bool {
        return items.count > 0
    }
    
    func generate() -> RegularExpressionCaptureGroupGenerator {
        return RegularExpressionCaptureGroupGenerator(items: items[0..<items.count])
    }
    
    subscript (i: Int) -> String {
        return items[i]
    }
}

infix operator =~ {}
infix operator !~ {}

func =~ (string: String, pattern: String) -> RegularExpressionMatchResult {
    let options: NSRegularExpressionOptions = [.AnchorsMatchLines, .UseUnixLineSeparators]
    
    do {
        let expression = try NSRegularExpression(pattern: pattern, options: options)
        let matchRange = NSRange(location: 0, length: (string as NSString).length)
        
        var matches: Array<String> = []
        
        expression.enumerateMatchesInString(string, options: [], range: matchRange, usingBlock: { (result, flags, stop) -> Void in
            guard let result = result else { return }
            
            let subStr = (string as NSString).substringWithRange(result.range)
            matches.append(subStr)
            
            for i in 1..<result.numberOfRanges {
                matches.append((string as NSString).substringWithRange(result.rangeAtIndex(i)))
            }
        })
        return RegularExpressionMatchResult(items: matches)
    }
    catch {
        return RegularExpressionMatchResult(items: [])
    }
}

func !~ (string: String, pattern: String) -> Bool {
    return !(string =~ pattern)
}
