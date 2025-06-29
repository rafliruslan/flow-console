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
import Combine
import Dispatch

@testable import SSH

class SSHErrorTests: XCTestCase {
  
  /**
   Tests that haven't been covered as there's no way to do it:
   - SSHError.noClient
   - SSHError.noChannel
   - SSHError.again
   - SSHError.notImplemented(_:)
   */
  
  /**
   SSHError.authError(:) is thrown when trying to use a method to authenticate on a host that's not allowed.
   In this case is trying to use `AuthNone()` as an authetnication method for a host that doesn't accept it.
   */
  func testAuthError() {
    let config = SSHClientConfig(
      user: Credentials.wrongPassword.user,
      port: Credentials.port,
      authMethods: []
    )
    
    var completion: Any? = nil

    SSHClient
      .dial(Credentials.wrongPassword.host, with: config)
      .noOutput(
        test: self,
        receiveCompletion: {
          completion = $0
        }
      )
    
    assertCompletionFailure(completion, withError: .authError(msg: ""))
  }
  
  func testConnectionError() {
    let config = SSHClientConfig(
      user: Credentials.wrongHost.user,
      port: Credentials.port,
      authMethods: [AuthPassword(with: Credentials.wrongHost.password)]
    )

    var completion: Any? = nil

    SSHClient.dial(Credentials.wrongHost.host, with: config)
      .noOutput(
        test: self,
        receiveCompletion: {
          completion = $0
        }
      )
    
    assertCompletionFailure(completion, withError: .connError(msg: ""))
  }
  
  /**
   Trying to authenticate against a host with either incorrect username or password credentials
   */
  func testAuthFailed() {
    let authMethods = [AuthPassword(with: Credentials.wrongPassword.password)]
    
    let config = SSHClientConfig(
      user: Credentials.wrongPassword.user,
      port: Credentials.port,
      authMethods: authMethods
    )
    
    var completion: Any? = nil

    SSHClient.dial(Credentials.wrongPassword.host, with: config)
      .noOutput(
        test: self,
        receiveCompletion: {
          completion = $0
        }
      )
    assertCompletionFailure(completion, withError: .authFailed(methods: authMethods))
  }
  
  /**
   Given a wrong/fake IP it should fail as the host couldn't be translated to a usable IP.
   */
  func testCouldntResolveHostAddress() throws {
    let config = SSHClientConfig(
      user: Credentials.regularUser,
      port: Credentials.port,
      authMethods: [AuthPassword(with: Credentials.regularUserPassword)]
    )
    
    var completion: Any? = nil
    
    SSHClient.dial(Credentials.incorrectIpHost, with: config)
      .noOutput(
        test: self,
        receiveCompletion: {
          completion = $0
        }
      )
    
    assertCompletionFailure(completion, withError: .connError(msg: "Socket error: No such file or directory"))
  }
}
