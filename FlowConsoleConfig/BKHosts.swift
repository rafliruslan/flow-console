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


extension BKHosts {
  static func sshConfig() throws -> SSHConfig {
    let config = SSHConfig()
    
    let hosts = BKHosts.allHosts() ?? []
    for h in hosts {
      var cfg: [(String, Any)] = []
      if let user = h.user, !user.isEmpty {
        cfg.append(("User", user))
      }
      if let port = h.port {
        cfg.append(("Port", port.intValue))
      }
      if let hostName = h.hostName, !hostName.isEmpty {
        cfg.append(("HostName", hostName))
      }
      if let key = h.key, !key.isEmpty, key != "None" {
        cfg.append(("IdentityFile", key))
      }
      if let proxyCmd = h.proxyCmd, !proxyCmd.isEmpty {
        cfg.append(("ProxyCommand", proxyCmd))
      }
      if let proxyJump = h.proxyJump, !proxyJump.isEmpty {
        cfg.append(("ProxyJump", proxyJump))
      }
      if let agentForwardPrompt = h.agentForwardPrompt,
         agentForwardPrompt.intValue > 0 {
        cfg.append(("ForwardAgent", "yes"))
      }
      if let sshConfigAttachment = h.sshConfigAttachment, !sshConfigAttachment.isEmpty {
        sshConfigAttachment.split(whereSeparator: \.isNewline).forEach { line in
          let components = line
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: CharacterSet(charactersIn: " \t"))
          if components.count >= 2,
             components[0] != "#" {
            cfg.append((components[0], components[1...].joined(separator: " ")))
          }
        }
      }
      
      try config.add(alias: h.host, cfg: cfg)
    }
    
    return config
  }
  
  @objc public static func saveAllToSSHConfig() {
    do {
      let config = try sshConfig()
      
      let configStr =
"""
# ATTENTION! THIS IS GENERATED FILE. DO NOT CHANGE IT DIRECTLY.
# GENERATED \(Date.now.ISO8601Format())
#
# Use config command do configure your hosts
# Or put your configuration to ~/.ssh/config

\(config.string())
"""

      guard
        let data = configStr.data(using: .utf8),
        let url = FlowConsolePaths.blinkSSHConfigFileURL()
      else {
        // TODO As this file is basically our own, we may want to report
        // errors during transformation by writing somewhere as well.
        print("can't convert to data")
        return
      }
      
      try data.write(to: url)
      
    } catch {
      // TODO Throw and capture somewhere else.
      print(error)
    }
  }
}
