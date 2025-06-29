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

@testable import Blink

final class SSHCommandTest: XCTestCase {
  func testSSHCommandParams() throws {
    var cmd: SSHCommand
    XCTAssertThrowsError(try SSHCommand.parse(["-t", "-T", "user@host"]))
    XCTAssertThrowsError(try SSHCommand.parse(["-o", "ForwardAgent", "yes", "user@host"]))
    cmd = try SSHCommand.parse(["-L", "11:forward:00", "-o", "ForwardAgent=yes", "user@host","-vv", "-p", "2222", "-L", "forward", "--", "cat", "-v", "hello"])
    XCTAssertTrue(cmd.customPort == 2222)
    XCTAssertTrue(cmd.command == ["cat", "-v", "hello"])
    XCTAssertTrue(cmd.localForward.count == 2)
    // Resolved at the SSH Config level
    XCTAssertTrue(cmd.agentForward == false)
    XCTAssertTrue(cmd.verbosity == 2)
  }
}
