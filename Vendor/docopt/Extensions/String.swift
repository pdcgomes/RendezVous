//
//  String.swift
//  docopt
//
//  Created by Pavel S. Mazurin on 2/28/15.
//  Copyright (c) 2015 kovpas. All rights reserved.
//

import Foundation

internal extension String {
    func partition(separator: String) -> (String, String, String) {
        let components = self.componentsSeparatedByString(separator)
        if components.count > 1 {
            return (components[0], separator, separator.join(components[1..<components.count]))
        }
        return (self, "", "")
    }
    
    func strip() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    func findAll(regex: String, flags: NSRegularExpressionOptions) -> [String] {
        do {
            let re = try NSRegularExpression(pattern: regex, options: flags)
            let all = NSMakeRange(0, self.characters.count)
            if let matches = re.matchesInString(self, options: [], range: all) as? [NSTextCheckingResult] {
                return matches.map {self[$0.rangeAtIndex(1)].strip()}
            }
        }
        catch {}
        
        return []
    }
    
    func split() -> [String] {
        return Swift.split(self.characters, isSeparator: {$0 == " " || $0 == "\n"}).map(String.init)
    }
    
    func split(regex: String) -> [String] {
        do {
            let re = try NSRegularExpression(pattern: regex, options: [.DotMatchesLineSeparators])
            
            let all = NSMakeRange(0, self.characters.count)
            var result = [String]()
            if let matches = re.matchesInString(self, options: [], range: all) as? [NSTextCheckingResult] where matches.count > 0 {
                var lastEnd = 0
                for match in matches {
                    let range = match.rangeAtIndex(1)
                    if range.location != NSNotFound {
                        if (lastEnd != 0) {
                            result.append(self[lastEnd..<match.range.location])
                        } else if range.location == 0 {
                            // from python docs: If there are capturing groups in the separator and it matches at the start of the string,
                            // the result will start with an empty string. The same holds for the end of the string:
                            result.append("")
                        }
                        
                        result.append(self[range])
                        lastEnd = range.location + range.length
                        if lastEnd == self.characters.count {
                            // from python docs: If there are capturing groups in the separator and it matches at the start of the string,
                            // the result will start with an empty string. The same holds for the end of the string:
                            result.append("")
                        }
                    } else {
                        result.append(self[lastEnd..<match.range.location])
                        lastEnd = match.range.location + match.range.length
                    }
                }
                if lastEnd != self.characters.count {
                    result.append(self[lastEnd..<self.characters.count])
                }
                return result
            }
        }
        catch {
            return [self]
        }

        return [self]
    }
    
    func isupper() -> Bool {
        let charset = NSCharacterSet.uppercaseLetterCharacterSet().invertedSet
        return self.rangeOfCharacterFromSet(charset) == nil
    }
    
    subscript(i: Int) -> Character {
        return self[advance(startIndex, i)]
    }
    
    subscript(range: Range<Int>) -> String {
        return self[advance(startIndex, range.startIndex)..<advance(startIndex, range.endIndex)]
    }

    subscript(range: NSRange) -> String {
        return self[range.location..<range.location + range.length]
    }
}
