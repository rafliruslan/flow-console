//////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Copyright (C) 2016-2023 Flow Console Project
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
// In addition, Flow Console is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Flow Console Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
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
