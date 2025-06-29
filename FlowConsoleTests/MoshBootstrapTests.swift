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
import XCTest

import SSH

@testable import Blink

final class MoshBootstrapTests: XCTestCase {
  var cancellableBag: Set<AnyCancellable> = []
  
  func testMoshBootstrap() throws {
    print("connecting...")
    
    let expectConn = self.expectation(description: "Connection established")
    
    var connection: SSHClient!
    SSHClient.dial(SSHClientConfig.testHost, with: .testConfig)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { conn in
          connection = conn
          expectConn.fulfill()
        }).store(in: &cancellableBag)

    wait(for: [expectConn], timeout: 5)

    print("connected")
    
    let expectBootstrap = self.expectation(description: "Mosh bootstrapped")
    let logger = MoshLogger(output: OutputStream(file: stdout))

    InstallStaticMosh(promptUser: false, logger: logger)
      .start(on: connection)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { moshServerPath in
          print("Mosh server path at: \(moshServerPath)")
          expectBootstrap.fulfill()
        }
      ).store(in: &cancellableBag)
    
    wait(for: [expectBootstrap], timeout: 30)
  }
  
  func testMoshDownloadBinaries() throws {
    let logger = MoshLogger(output: OutputStream(file: stdout), logLevel: .info)
    let moshBootstrap = InstallStaticMosh(promptUser: false, logger: logger)
    
    moshBootstrap.getMoshServerBinary(platform: .Darwin, architecture: .X86_64)
      .assertNoFailure()
      .sink(test: self)

    moshBootstrap.getMoshServerBinary(platform: .Darwin, architecture: .Arm64)
      .assertNoFailure()
      .sink(test: self)
    
    moshBootstrap.getMoshServerBinary(platform: .Linux, architecture: .Amd64)
      .assertNoFailure()
      .sink(test: self)
    
    moshBootstrap.getMoshServerBinary(platform: .Linux, architecture: .Arm64)
      .assertNoFailure()
      .sink(test: self)
    
    moshBootstrap.getMoshServerBinary(platform: .Linux, architecture: .Armv7)
      .assertNoFailure()
      .sink(test: self)
  }
}

// TODO Test getting parameters from expected Mosh output. Important in case we find weird cases, but not critical.
// TODO - We could test the Bootstrap request flow, separating it to a different object. Complicated and not sure what extra insight we would get from it.
// TODO Test configurations from .ssh/config + parameters. How? This will have to go to the QA instructions.

extension SSHClientConfig {
  static let testHost = "localhost"
  static let testConfig = SSHClientConfig(
    user: "asdf",
    port: "22",
    authMethods: [AuthPassword(with: "")],
    loggingVerbosity: .debug
  )
}
