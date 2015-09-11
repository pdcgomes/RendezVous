//
//  StringColorizer.swift
//  RendezVous
//
//  Created by Pedro Gomes on 11/09/2015.
//  Copyright © 2015 Pedro Gomes. All rights reserved.
//

import Foundation

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public enum AnsiColorCode : UInt {
    case Black   = 0
    case Red     = 1
    case Green   = 2
    case Yellow  = 3
    case Blue    = 4
    case Magenta = 5
    case Cyan    = 6
    case White   = 7
    case Default = 9

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public init?(rawValue: UInt) {
        var value: UInt
        
        switch rawValue {
            case 30...39: value = rawValue - 30; break
            case 40...49: value = rawValue - 40; break
            case 60...69: value = rawValue - 60; break
            default: value = rawValue
        }
        
        switch value {
            case 0: self = .Black;   break
            case 1: self = .Red;     break
            case 2: self = .Green;   break
            case 3: self = .Yellow;  break
            case 4: self = .Blue;    break
            case 5: self = .Magenta; break
            case 6: self = .Cyan;    break
            case 7: self = .White;   break
            case 9: self = .Default; break
            
        default: return nil
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func lightColor() -> UInt {
        switch self.rawValue {
            case 0...7: return self.rawValue + 60
            default:    return self.rawValue
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func foregroundColor() -> UInt {
        return self.rawValue + 30
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    func backgroundColor() -> UInt {
        return self.rawValue + 40
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public enum AnsiModeCode : UInt {
    case Default   = 0
    case Bold      = 1
    case Italic    = 3
    case Underline = 4
    case Inverse   = 7
    case Hide      = 8
    case Strike    = 9
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
struct ANSISequence: CustomStringConvertible {
    var modeCode:       UInt
    var foregroundCode: UInt
    var backgroundCode: UInt
    var string:         String
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    init(foreground: AnsiColorCode = .Default, background: AnsiColorCode = .Default, mode: AnsiModeCode = .Default, string: String) {
        self.foregroundCode = foreground.foregroundColor()
        self.backgroundCode = background.backgroundColor()
        self.modeCode       = mode.rawValue
        self.string         = string
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    var description: String {
        let codeSequence = [modeCode, foregroundCode, backgroundCode]
            .map({ String($0) })
            .joinWithSeparator(";")
        
        return "\u{001b}[\(codeSequence)m" + string + "\u{001b}[0m"
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
public extension String {
    
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func colorize(text: AnsiColorCode = .Default, background: AnsiColorCode = .Default, mode: AnsiModeCode = .Default) -> String {

        let (hasSequence, sequence) = extractANSISequence()
        
        if hasSequence {
            let seq = sequence!
            return ANSISequence(
                foreground: (text == .Default ? AnsiColorCode(rawValue: seq.foregroundCode)! : text),
                background: (background == .Default ? AnsiColorCode(rawValue: seq.backgroundCode)! : background),
                mode: (mode == .Default ? AnsiModeCode(rawValue: seq.modeCode)! : mode),
                string: seq.string).description
        }
        
        return ANSISequence(
            foreground: text,
            background: background,
            mode: mode,
            string: self).description
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    public func printColorSamples() -> Void {
        let textColor       = ""
        let backgroundColor = ""
        
        print("\(textColor) on \(backgroundColor)")
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    // If we already have existing ANSI sequences, return them
    ////////////////////////////////////////////////////////////////////////////////
    private func extractANSISequence() -> (Bool, ANSISequence?) {
        
        let result = self =~ "\\u001B\\[([^m]*)m(.+?)\\u001B\\[0m"
        
        guard result else { return (false, nil) }

        let codes = result[1].componentsSeparatedByString(";").map({ UInt($0)! })

        let mode       = AnsiModeCode(rawValue: UInt(codes[0]))!
        let foreground = AnsiColorCode(rawValue: UInt(codes[1]))!
        let background = AnsiColorCode(rawValue: UInt(codes[2]))!
        
        return (true, ANSISequence(
            foreground: foreground,
            background: background,
            mode: mode,
            string: result[2]))
    }
}

////////////////////////////////////////////////////////////////////////////////
// Convenience methods and properties
////////////////////////////////////////////////////////////////////////////////
public extension String {
    
    ////////////////////////////////////////////////////////////////////////////////
    // Convenince text colorizer properties
    ////////////////////////////////////////////////////////////////////////////////
    var   black: String { return self.colorize(.Black)  }
    var     red: String { return self.colorize(.Red)    }
    var   green: String { return self.colorize(.Green)  }
    var  yellow: String { return self.colorize(.Yellow) }
    var    blue: String { return self.colorize(.Blue)   }
    var magenta: String { return self.colorize(.Magenta)}
    var    cyan: String { return self.colorize(.Cyan)   }
    var   white: String { return self.colorize(.White)  }

    ////////////////////////////////////////////////////////////////////////////////
    // Convenience background colorizer properties
    ////////////////////////////////////////////////////////////////////////////////
    var   on_black: String { return self.colorize(background: .Black)  }
    var     on_red: String { return self.colorize(background: .Red)    }
    var   on_green: String { return self.colorize(background: .Green)  }
    var  on_yellow: String { return self.colorize(background: .Yellow) }
    var    on_blue: String { return self.colorize(background: .Blue)   }
    var on_magenta: String { return self.colorize(background: .Magenta)}
    var    on_cyan: String { return self.colorize(background: .Cyan)   }
    var   on_white: String { return self.colorize(background: .White)  }

    ////////////////////////////////////////////////////////////////////////////////
    // Convenience mode setting properties
    ////////////////////////////////////////////////////////////////////////////////
    var      bold: String { return self.colorize(mode: .Bold)     }
    var underline: String { return self.colorize(mode: .Underline)}
    var    italic: String { return self.colorize(mode: .Italic)   }
    var   inverse: String { return self.colorize(mode: .Inverse)  }
    var    strike: String { return self.colorize(mode: .Strike)   }
}
