//////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Based on Blink Shell for iOS
// Original Copyright (C) 2016-2024 Blink Shell contributors
// Flow Console modifications Copyright (C) 2024 Flow Console Project
//
// This file is part of Flow Console.
//
// Flow Console is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Flow Console is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Flow Console. If not, see <http://www.gnu.org/licenses/>.
//
// Original Blink Shell project: https://github.com/blinksh/blink
// Flow Console project: https://github.com/rafliruslan/flow-console
//
////////////////////////////////////////////////////////////////////////////////


import Foundation


public enum ShellOutputFormatter {
  case raw,
       block,
       lineBySemicolon,
       beginEnd

  public func format(_ script: String) -> String {
    let commands = parseCommands(script)

    // Escape if no multi-line
    if commands.isEmpty {
      return ""
    } else if commands.count == 1 {
      return commands[0]
    }
    
    switch self {
    case .raw:
      return script
    case .lineBySemicolon:
      return commands.joined(separator: "; ")
    case .block:
      return script.wrapIn(prefix: "$(\n", suffix: "\n)")
    case .beginEnd:
      return script.wrapIn(prefix: "begin\n", suffix: "\nend")
    }
  }
  
  private func parseCommands(_ script: String) -> [String] {
    // Receives text and splits into multiple commands
    var currentCommand = ""
    var commands: [String] = []
    
    for line in script
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .components(separatedBy: .newlines) {
      let trimmedLine = line.trimmingCharacters(in: .whitespaces)

      if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
        continue
      }

      if trimmedLine.hasSuffix("\\") {
        currentCommand += line.appending("\n")
      } else {
        currentCommand += line
        commands.append(currentCommand)
        currentCommand = ""
      }
    }
    
    return commands
  }
}

extension String {
  func wrapIn(prefix: String, suffix: String) -> String {
    return "\(prefix)\(self)\(suffix)"
  }
}
