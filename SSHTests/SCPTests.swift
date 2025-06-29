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
import FlowConsoleFiles
import Combine
import Dispatch

@testable import SSH


class SCPTests: XCTestCase {
  
  func testSCPInit() throws {
    throw XCTSkip("Disabled SCP for now.")

    let scp = SSHClient
      .dialWithTestConfig()
      .flatMap() { c -> AnyPublisher<SCPClient, Error> in
        print("Received connection")
        return SCPClient.execute(using: c, as: .Sink, root: "/tmp")
      }
      .assertNoFailure()
      .lastOutput(test: self)
    
    dump(scp)
    XCTAssertNotNil(scp)
  }
  
  func testSCPFileCopyFrom() throws {
    throw XCTSkip("Disabled SCP for now.")

    let expectation = self.expectation(description: "sftp")
    
    var connection: SSHClient?
    var sftp: SFTPTranslator?
    var scp: SCPClient?
    var totalWritten: UInt64 = 0
    
    let c1 = SSHClient.dialWithTestConfig()
      .flatMap() { conn -> AnyPublisher<SCPClient, Error> in
        connection = conn
        return SCPClient.execute(using: conn, as: .Sink, root: "/tmp")
      }.assertNoFailure()
      .sink { client in
        scp = client
        expectation.fulfill()
      }
    
    wait(for: [expectation], timeout: 15)
    
    let expectation2 = self.expectation(description: "scp")
    let c2 = connection?
      .requestSFTP()
      .tryMap  { try SFTPTranslator(on: $0) }
      .flatMap { client -> AnyPublisher<Translator, Error> in
      sftp = client
      return sftp!.walkTo("Xcode_12.0.1.xip")
    }.flatMap { sourceFile in
      return scp!.copy(from: [sourceFile])
    }
    .sink(receiveCompletion: { completion in
      switch completion {
      case .finished:
        expectation2.fulfill()
      case .failure(let error):
        // Problem here is we can have both SFTP and SSHError
        XCTFail("Crash \(error)")
      }
    }, receiveValue: { report in
      totalWritten += report.written
    })
    
    wait(for: [expectation2], timeout: 1000)
    // Check total copied
    XCTAssertTrue(totalWritten == 11210638916, "Wrote \(totalWritten)")
  }
  
  // TODO func testSCPEmptyFile
  
  func testSCPDirectoryCopyFrom() throws {
    throw XCTSkip("Disabled SCP for now.")

    let config = SSHClientConfig(user: "carlos", authMethods: [AuthPassword(with: "")])
    
    let expectation = self.expectation(description: "scp")
    
    var connection: SSHClient?
    var sftp: SFTPTranslator?
    var scp: SCPClient?
    //var totalWritten = 0
    var filesWritten = 0
    
    let c1 = SSHClient.dial("localhost", with: config)
      .flatMap() { conn -> AnyPublisher<SCPClient, Error> in
        connection = conn
        return SCPClient.execute(using: conn, as: [.Sink, .Recursive], root: "/tmp/new")
      }.assertNoFailure()
      .sink { client in
        scp = client
        expectation.fulfill()
      }
    
    wait(for: [expectation], timeout: 15)
    
    var connectionSFTP: SSHClient?
    let expectation2 = self.expectation(description: "sftp")
    let c2 = SSHClient.dial("localhost", with: config)
      .flatMap() { conn -> AnyPublisher<SFTPClient, Error> in
        connectionSFTP = conn
        return conn.requestSFTP()
      }
      .tryMap { try SFTPTranslator(on: $0) }
      .flatMap { client -> AnyPublisher<Translator, Error> in
        sftp = client
        return sftp!.walkTo("playgrounds")
      }.flatMap { dir in
        return scp!.copy(from: [dir])
      }
      .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
          expectation2.fulfill()
        case .failure(let error):
          // Problem here is we can have both SFTP and SSHError
          XCTFail("Crash \(error)")
        }
      }, receiveValue: { report in
        print("\(report.name) - \(report.written) of \(report.size)")
      })
    
    wait(for: [expectation2], timeout: 1000)
    //XCTAssertTrue(filesWritten > 0, "No files written")
    //XCTAssertTrue(totalWritten > 0, "Wrote \(totalWritten)")
  }
  
  // Copy path from scp to path on sftp
  func testCopyTo() throws {
    throw XCTSkip("Disabled SCP for now.")
    
    let expectation = self.expectation(description: "scp")
    
    var connection: SSHClient?
    var sftp: SFTPTranslator?
    var scp: SCPClient?
    
    let c1 = SSHClient.dialWithTestConfig()
      .flatMap() { conn -> AnyPublisher<SCPClient, Error> in
        connection = conn
        return SCPClient.execute(using: conn, as: [.Source, .Recursive], root: "/Users/carlos/tmp/*")
      }
      .assertNoFailure()
      .sink { client in
        scp = client
        expectation.fulfill()
      }
    
    wait(for: [expectation], timeout: 15)
    
    let expectation2 = self.expectation(description: "sftp")
    let c2 = connection?
      .requestSFTP()
      .tryMap { try SFTPTranslator(on: $0) }
      .flatMap { client -> AnyPublisher<Translator, Error> in
      sftp = client
      return sftp!.walkTo("/tmp/test")
    }.flatMap { dir in
      return scp!.copy(to: dir)
    }
    .sink(receiveCompletion: { completion in
      switch completion {
      case .finished:
        expectation2.fulfill()
      case .failure(let error):
        // Problem here is we can have both SFTP and SSHError
        XCTFail("Crash \(error)")
      }
    }, receiveValue: { report in
      print("\(report.name) - \(report.written) of \(report.size)")
    })
    
    wait(for: [expectation2], timeout: 1000)
  }
}
