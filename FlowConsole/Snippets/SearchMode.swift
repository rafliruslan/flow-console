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

enum SearchMode {
  case general
  case insert
  case command
  case host
  case prompt
  case help
  case history
  
  func toString() -> String {
    switch self {
    case .general: return "General"
    case .insert: return "Insert"
    case .command: return "Command"
    case .host: return "Host"
    case .prompt: return "AI"
    case .help: return "Help"
    case .history: return "History"
    }
  }
  
  func toSymbol() -> String {
    switch self {
    case .general: return ""
    case .insert: return "<"
    case .command: return ">"
    case .host: return "@"
    case .prompt: return "$"
    case .help: return "?"
    case .history: return "!"
    }
  }
}
