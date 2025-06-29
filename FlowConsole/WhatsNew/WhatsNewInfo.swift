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


class WhatsNewInfo {
  // https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
  static private let defaults = UserDefaults.standard
  static private let MaxDisplayCount = 5
  static private let LastVersionKey = "LastVersionDisplay"
  static private var LastVersion: String? { defaults.string(forKey: LastVersionKey) }
  static private let CountVersionDisplayKey = "CountVersionDisplayKey"
  static private var CountVersionDisplay: Int? { defaults.integer(forKey: CountVersionDisplayKey) }
  static private var Version: String { UIApplication.flowConsoleMajorVersion() }
  static private var prompt: String {
    "\u{1B}[30;48;5;45m New Blink \(Version)! \u{1B}[0m\u{1B}[38;5;45m\u{1B}[0m Check \"whatsnew\""
  }
  static private var firstUsagePrompt: String {
    """
\u{1B}[30;48;5;45m Type \u{1B}[0m\u{1B}[38;5;45m\u{1B}[0m
ssh, mosh - Connect to remote
code - Code session
build - Build dev environments
config - Hosts, keys, keyboard, etc...
<tab> - Display list of commands
help - Quick help
"""
  }
  // static private let BlinkClassicUpdatedDisplayKey = "BlinkClassicUpdatedDisplayKey"
  // static private var BlinkClassicUpdatedDisplay: String { defaults.string(forKey: BlinkClassicUpdatedDisplayKey) }
  // static private let BlinkClassicVersion = "18.2"

  private init() {}

  static func mustDisplayInitialPrompt() -> String? {
    if isFirstInstall() {
      promptDisplayed()
      return firstUsagePrompt
    }

    if mustDisplayVersionPrompt() {
      promptDisplayed()
      return prompt
    }

    return nil
  }

  // static func mustDisplayBlinkClassicAlert() -> Bool {
  //   if let lastUpdate = BlinkClassicUpdatedDisplay {
  //     if versionsAreEqualIgnoringPatch(lastUpdate, BlinkClassicVersion) {
  //       return false
  //     }
  //   }

  //   return false
  // }

  // static func blinkClassicAlert() -> UIAlertController {
  //   let alert = UIAlertController(title: "Blink Classic plan", message: "Your Blink Classic has been updated", preferredStyle: .alert)
  //   alert.addAction(UIAlertAction(title: "OK"))
  //   alert.addAction(UIAlertAction(title: "Update to Blink+"))
  // }

  static func setNewVersion() {
    defaults.set(Version, forKey: LastVersionKey)
    defaults.set(0, forKey: CountVersionDisplayKey)
  }

  static func isFirstInstall() -> Bool {
    Self.LastVersion == nil ? true : false
  }

  static private func mustDisplayVersionPrompt() -> Bool {
    let version = Version

    if let lastVersion = Self.LastVersion,
       let displayCount = Self.CountVersionDisplay {
      return (displayCount < MaxDisplayCount) && !versionsAreEqualIgnoringPatch(v1: version, v2: lastVersion)
    } else {
      return true
    }
  }

  static private func versionsAreEqualIgnoringPatch(v1: String, v2: String) -> Bool {
    v1.split(separator: ".").prefix(upTo: 2) == v2.split(separator: ".").prefix(upTo: 2)
  }

  static private func promptDisplayed() {
    let count = defaults.integer(forKey: CountVersionDisplayKey) + 1

    if count == MaxDisplayCount {
      setNewVersion()
    } else {
      defaults.set(count, forKey: CountVersionDisplayKey)
    }
  }
}
