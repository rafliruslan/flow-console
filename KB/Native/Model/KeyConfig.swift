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


import Combine

enum KeyPress {
  case none
  case escape
  case escapeOnRelease
  
  var usageHint: String {
    switch self {
    case .none: return ""
    case .escape: return "Sends Escape on key down. Use this option if you want key to behave like missing Esc key."
    case .escapeOnRelease: return "Send Escape on key up if no other key where pressed. Useful with modifier as Ctrl option."
    }
  }
}

class KeyConfig: ObservableObject, Codable {
  let code: KeyCode
  @Published var up: KeyAction
  @Published var down: KeyAction
  @Published var mod: KeyModifier
  @Published var ignoreAccents: Bool
  
  init(code: KeyCode,
       up: KeyAction,
       down: KeyAction,
       mod: KeyModifier,
       ignoreAccents: Bool = true
  ) {
    self.code          = code
    self.up            = up
    self.down          = down
    self.mod           = mod
    self.ignoreAccents = ignoreAccents
  }
  
  var press: KeyPress {
    get {
      if down == .escape {
        return .escape
      } else if up == .escape {
        return .escapeOnRelease
      }
      return .none
    }
    set {
      self.down = .none
      self.up = .none
      switch newValue {
      case .escape:
        self.down = .escape
      case .escapeOnRelease:
        self.up = .escape
      default:
        break
      }
    }
  }
  
  func pair(right: KeyConfig) -> KeyConfigPair {
    KeyConfigPair(left: self, right: right, bothAsLeft: true)
  }
  
  func pair(code: KeyCode) -> KeyConfigPair {
    KeyConfigPair(
      left: self,
      right: KeyConfig(
        code: code,
        up: up,
        down: down,
        mod: mod,
        ignoreAccents: ignoreAccents
      )
    )
  }
  
  var fullName: String { code.fullName }
  
  var description: String {
    let upDesc = up.description
    let modDesc = mod.description
    let downDesc = down.description
    var res: [String] = []
    
    if !downDesc.isEmpty {
      res.append(downDesc)
    }
    
    if !modDesc.isEmpty {
      res.append("[\(modDesc)]")
    }
    
    if !upDesc.isEmpty {
      res.append(upDesc)
    }
    
    return res.joined(separator: ", ")
  }
  
  static var capsLock: KeyConfig {
    KeyConfig(code: .capsLock, up: .none, down: .none, mod: .none)
  }
  
  // - MARK: Codable
  
  enum Keys: CodingKey {
    case code
    case up
    case down
    case mod
    case ignoreAccents
  }
  
  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: Keys.self)
    try c.encode(code,          forKey: .code)
    try c.encode(up,            forKey: .up)
    try c.encode(mod,           forKey: .mod)
    try c.encode(down,          forKey: .down)
    try c.encode(ignoreAccents, forKey: .ignoreAccents)
  }
  
  required convenience init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Keys.self)
    let code          = try c.decode(KeyCode.self,     forKey: .code)
    let up            = try c.decode(KeyAction.self,   forKey: .up)
    let down          = try c.decode(KeyAction.self,   forKey: .down)
    let mod           = try c.decode(KeyModifier.self, forKey: .mod)
    let ignoreAccents = try c.decode(Bool.self,        forKey: .ignoreAccents)
    self.init(code: code, up: up, down: down, mod: mod, ignoreAccents: ignoreAccents)
  }

}
