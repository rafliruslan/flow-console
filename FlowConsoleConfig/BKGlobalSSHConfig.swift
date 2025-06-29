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

import SSHConfig


public class BKGlobalSSHConfig: NSObject, NSSecureCoding {
  let user: String

  public static var supportsSecureCoding: Bool = true
 
  @objc public init(user: String) {
    self.user = user
    
    super.init()
  }

  public required init?(coder decoder: NSCoder) {
    guard let user = decoder.decodeObject(of: [NSString.self], forKey: "user") as? String
    else {
      return nil
    }

    self.user = user
  }

  public func encode(with coder: NSCoder) {
    coder.encode(user, forKey: "user")
  }

  @objc public func saveFile() {
    do {
      let config = SSHConfig()

      // TODO If we decide to add values, we need to figure out when to overwrite it.
      // Probably as part of the Default config.
      // Not sure if now it was happening on every run.
      try config.add(alias: "*", cfg: [("User", self.user),
                                       ("ControlMaster", "auto"),
                                       ("SendEnv", "LANG"),
                                       ("Compression", "yes"),
                                       ("CompressionLevel", "6")])
   
      // Config does not currently allow for single lines
      let configString = """
Include ssh_config
Include ../.ssh/config

\(config.string())
"""
      guard let data = configString.data(using: .utf8),
            let url = FlowConsolePaths.blinkGlobalSSHConfigFileURL()
      else {
        print("Could not write global ssh configuration")
        return
      }

      try data.write(to: url)
    } catch(let error) {
      // TODO We could/should rely on a Log + Alert mechanism.
      print(error.localizedDescription)
    }
  }
}
