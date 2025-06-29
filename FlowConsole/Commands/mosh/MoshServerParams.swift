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


struct MoshServerParams {
  let key: String
  let udpPort: String
  let remoteIP: String
  let versionString: String?
}

extension MoshServerParams {
  init(parsing output: String, remoteIP: String?) throws {
    if let remoteIP = remoteIP {
      self.remoteIP = remoteIP
    } else {
      let remoteIPPattern = try! NSRegularExpression(
        pattern: "(?m)^MOSH SSH_CONNECTION (\\S*) (\\d*) (\\S*) (\\d*)$",
        options: []
      )
      if let remoteIPMatch = remoteIPPattern.firstMatch(
           in: output,
           options: [],
           range: NSRange(location: 0, length: output.utf8.count)
         ) {
        self.remoteIP = String(output[Range(remoteIPMatch.range(at: 3), in: output)!])
      } else {
        throw MoshError.NoRemoteServerIP
      }
    }

    let connectPattern = try! NSRegularExpression(
      pattern: "(?m)^MOSH CONNECT (\\d+) (\\S*)$",
      options: []
    )
    if let connectMatch = connectPattern.firstMatch(
         in: output,
         options: [],
         range: NSRange(output.startIndex..., in: output)
       ) {
      self.udpPort = String(output[Range(connectMatch.range(at: 1), in: output)!])
      self.key = String(output[Range(connectMatch.range(at: 2), in: output)!])
    } else {
      throw MoshError.NoMoshServerArgs
    }

    let versionStringPattern = try! NSRegularExpression(
      pattern: "\\+blink-(\\d+\\.\\d+\\.\\d+)",
      options: []
    )
    if let versionStringMatch = versionStringPattern.firstMatch(
      in: output,
      options: [],
      range: NSRange(output.startIndex..., in: output)
    ) {
      self.versionString = String(output[Range(versionStringMatch.range(at: 1), in: output)!])
    } else {
      self.versionString = nil
    }
  }

  func isRunningOlderStaticVersion() -> Bool {
    guard let versionString = self.versionString else {
      return false
    }

    if MoshServerBlinkVersion.compare(versionString, options: .numeric) == .orderedDescending {
      return true
    } else {
      return false
    }
  }
}
