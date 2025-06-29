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


import XCTest

@testable import FlowConsoleConfig

class FlowConsoleConfigTests: XCTestCase {
  let fm = FileManager.default
  let hostAlias = "test"
  override func setUpWithError() throws {
    BKHosts.loadHosts()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    let sshConfigAttachment =
"""
Compression yes
CompressionLevel 8
ControlMaster no
"""
    
    let _ = BKHosts.saveHost(hostAlias,
                                withNewHost: hostAlias,
                                hostName: "localhost",
                                sshPort: "22",
                                user: "glenda",
                                password: "password",
                                hostKey: "id_rsa",
                                moshServer: "",
                                moshPortRange: "",
                                startUpCmd: "",
                                prediction: BKMoshPrediction(rawValue: 0),
                                proxyCmd: "exec nc %h:%p",
                                proxyJump: "jumphost",
                                sshConfigAttachment: sshConfigAttachment,
                                fpDomainsJSON: "")
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    try fm.removeItem(at: URL(fileURLWithPath: FlowConsolePaths.blinkHostsFile()))
    try fm.removeItem(at: FlowConsolePaths.blinkSSHConfigFileURL())
  }
  
func testBKHostsToSSHConfig() throws {
  let hostString = try BKHosts.sshConfig().string()
  let expectConfig = ["Host \(hostAlias)",
                      "User glenda",
                      "Port 22",
                      "HostName localhost",
                      "ProxyCommand exec nc %h:%p",
                      "ProxyJump jumphost",
                      "Compression yes",
                      "ControlMaster no",
                      "IdentityFile id_rsa"
  ]

  expectConfig.forEach { row in
    if !hostString.contains(row) {
      XCTFail("\(row) not found on hostString")
    }
  }
  
  // Password should be skipped
  XCTAssertFalse(hostString.contains("Password password"))
}
  
  func testSSHConfigToSSHClientConfig() throws {
    // Test conversion to BKSSHHost.
    // TODO First issue is that this BKSSHHost is of an "undefined" format, what
    // makes it difficult to match to the one coming from SSHConfig as [String:Any].
    // TODO One issue for example is the "other commands" on SSHCommand.
    // A yes/no, will not get translated to true false sequence.
    let baseHost = try BKSSHHost(content: ["user": "no-password",
                                           "port": "2222",
                                           "compression": "no",
                                           "sendenv": "TERM LC*"])

    let _ = try BKConfig().bkSSHHost(hostAlias, extending: baseHost)
    guard let env = baseHost.sendEnv else {
      XCTFail("No env received")
      return
    }
    XCTAssert(env.contains("TERM") &&
              env.contains("LC*"), "List mapping failed")
  }
}
