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
import Foundation
import XCTest

import FlowConsoleFiles
import SSH
@testable import FlowConsoleFileProvider


final class FileTranslatorFactoryTests: XCTestCase {
  override func setUpWithError() throws {
    BlinkLogging.handle(BlinkLoggingHandlers.print)
  }

  func testSFTPFactory() throws {
    // The issue is that the SSHClient is dropped all the time. This shouldn't happen, the client should be maintained, and only
    // reset when the connection is closed.
    let providerPath = try BlinkFileProviderPath(TestFactoryConfigurator.LocalTestPath)

    var rootTranslatorPublisher = try FileTranslatorFactory.rootTranslator(for: providerPath, configurator: TestFactoryConfigurator())
      .print("rootTranslatorPublisher")
    var rootTranslator: Translator? = nil

    print("First Operation")
    let expectFirstOperation = expectation(description: "First Operation")
    let c1 = rootTranslatorPublisher.flatMap { t in
      rootTranslator = t
      return t.cloneWalkTo("fps")
    }
      .flatMap { $0.directoryFilesAndAttributes() }
      .assertNoFailure()
      //.print("first operation")
      .sink { attrs in
        print("First Operation \(attrs.count) elements")
        expectFirstOperation.fulfill()
      }

    wait(for: [expectFirstOperation], timeout: 2)

    print("Second Operation")
    let expectSecondOperation = expectation(description: "Second Operation")
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))

    let c2 = Just(rootTranslator!).flatMap { $0.cloneWalkTo("fps") }
        .flatMap { $0.directoryFilesAndAttributes() }
        .assertNoFailure()
        .sink { attrs in
          print("Second Operation \(attrs.count) elements")
          rootTranslator = nil
          expectSecondOperation.fulfill()
        }
    wait(for: [expectSecondOperation], timeout: 2)

    print("Third Operation")
    let expectThirdOperation = expectation(description: "Third operation")
    let c3 = rootTranslatorPublisher.flatMap { $0.cloneWalkTo("fps") }
        .flatMap { $0.directoryFilesAndAttributes() }
        .assertNoFailure()
        .sink { attrs in
          print("Third Operation \(attrs.count) elements")
          expectThirdOperation.fulfill()
        }
    wait(for: [expectThirdOperation], timeout: 2)

    print("Fourth Operation - multiple connections at the same time")
    rootTranslatorPublisher = try FileTranslatorFactory.rootTranslator(for: providerPath, configurator: TestFactoryConfigurator())
      .print("rootTranslatorPublisher")
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))

    let expectOp1 = expectation(description: "Fourth Op. Op1")
    let c4Op1 = rootTranslatorPublisher.flatMap { t in
      return t.cloneWalkTo("fps")
    }
      .flatMap { $0.directoryFilesAndAttributes() }
      .assertNoFailure()
      //.print("first operation")
      .sink { _ in
        print("Fulfilled Op1")
        expectOp1.fulfill()
      }
    let expectOp2 = expectation(description: "Fourth Op. Op2")
    let c4Op2 = rootTranslatorPublisher.flatMap { t in
      return t.cloneWalkTo("fps")
    }
      .flatMap { $0.directoryFilesAndAttributes() }
      .assertNoFailure()
      //.print("first operation")
      .sink { _ in
        print("Fulfilled Op2")
        expectOp2.fulfill()
      }
    wait(for: [expectOp1, expectOp2], timeout: 2)
  }

  func testTranslatorConnection() throws {
    let providerPath = try BlinkFileProviderPath(TestFactoryConfigurator.LocalTestPath)
    var connection = FilesTranslatorConnection(providerPath: providerPath, configurator: TestFactoryConfigurator())

    //var rootTranslator: TranslatorPublisher = connection.rootTranslator
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))

    print("First Operation")
    let expectFirstOperation = expectation(description: "First Operation")
    let c1 = connection.rootTranslator
      .flatMap { $0.cloneWalkTo("fps") }
      .flatMap { $0.directoryFilesAndAttributes() }
      .assertNoFailure()
    //.print("first operation")
      .sink { attrs in
        print("First Operation \(attrs.count) elements")
        expectFirstOperation.fulfill()
      }

    wait(for: [expectFirstOperation], timeout: 2)
    print("==============================")

    print("Second Operation - Op1 be cancelled, Op2 succeed. Translator should not reset.")
    let expectSecondOperationOp1 = expectation(description: "Second Operation - Op1")
    let _ = connection.rootTranslator.flatMap { $0.cloneWalkTo("fps") }
        .flatMap { $0.directoryFilesAndAttributes() }
        .handleEvents(receiveCancel: {
          print("Second Operation Op 1 cancelled")
          expectSecondOperationOp1.fulfill()
        })
        .assertNoFailure()
        .sink { attrs in
          //print("Second Operation \(attrs.count) elements")
        }
    wait(for: [expectSecondOperationOp1], timeout: 2)

    let expectSecondOperationOp2 = expectation(description: "Second Operation - Op2")
    let c2 = connection.rootTranslator.flatMap { $0.cloneWalkTo("fps") }
        .flatMap { $0.directoryFilesAndAttributes() }
        .assertNoFailure()
        .sink { attrs in
          print("Second Operation \(attrs.count) elements")
          expectSecondOperationOp2.fulfill()
        }
    wait(for: [expectSecondOperationOp2], timeout: 2)
    print("==============================")

    print("Third Operation")
    connection = FilesTranslatorConnection(providerPath: providerPath, configurator: TestFactoryConfigurator())
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))

    let expectCancel = expectation(description: "Cancel connection")
    var cancel = connection.rootTranslator.flatMap { $0.cloneWalkTo("fps") }
        .flatMap { $0.directoryFilesAndAttributes() }
        .handleEvents(receiveCancel: {
          print("Cancel received")
          expectCancel.fulfill()
        })
        .assertNoFailure()
        .sink { _ in }

    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    cancel.cancel()
    wait(for: [expectCancel])

    let expectThirdOperation = expectation(description: "Third operation")

    let c3 = connection.rootTranslator.flatMap { $0.cloneWalkTo("fps") }
        .flatMap { $0.directoryFilesAndAttributes() }
        .assertNoFailure()
        .sink { attrs in
          print("Third Operation \(attrs.count) elements")
          expectThirdOperation.fulfill()
        }
    wait(for: [expectThirdOperation], timeout: 2)
    print("==============================")

    print("Fourth Operation - start connections at the same time")
    connection = FilesTranslatorConnection(providerPath: providerPath, configurator: TestFactoryConfigurator())
    // Note doing this will not re-evaluate the status of the connection. This is the returned publisher.
    // let rootTranslator = connection.rootTranslator
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))

    let expectOpOne = expectation(description: "Multiple ops - op1")
    let expectOpTwo = expectation(description: "Multiple ops - op2")
    let _c4One = connection.rootTranslator.print("op1").flatMap { $0.cloneWalkTo("fps") }
      .flatMap {
        $0.directoryFilesAndAttributes()
      }
      .assertNoFailure()
      .sink { attrs in
        print("fulfill one")
        expectOpOne.fulfill()
      }
    let _c4Two = connection.rootTranslator.print("op2")
      .flatMap { $0.cloneWalkTo("fps") }
      .flatMap {
        $0.directoryFilesAndAttributes()
      }
      .assertNoFailure()
      .sink { attrs in
        print("fulfill two")
        expectOpTwo.fulfill()
      }
    wait(for: [expectOpOne, expectOpTwo], timeout: 8)
    print("==============================")

  }

  // Should add tests here for the SSH and SFTP Connections.
  // Usage of translator in parallel. Reset connection. Reset SFTP channel, etc...
  public func testProxyConnection() throws {
    let providerPath = try BlinkFileProviderPath(TestProxyFactoryConfigurator.ProxyTestPath)

    var rootTranslatorPublisher: TranslatorPublisher? = try FileTranslatorFactory.rootTranslator(for: providerPath, configurator: TestProxyFactoryConfigurator())

    print("First Operation")
    let expectFirstOperation = expectation(description: "First Operation")
    let c1 = rootTranslatorPublisher!
      .flatMap { $0.directoryFilesAndAttributes() }
      .assertNoFailure()
    //.print("first operation")
      .sink { attrs in
        print("First Operation \(attrs.count) elements")
        expectFirstOperation.fulfill()
      }

    wait(for: [expectFirstOperation], timeout: 2)

    // Check the Proxy thread frees on exit.
    rootTranslatorPublisher = nil
  }
}

class TestFactoryConfigurator: FileTranslatorFactory.Configurator {
  static let LocalTestPath = "sftp:localhost:~/fps"

  func sshConfig(host title: String) throws -> (String, SSH.SSHClientConfig) {
    let config = SSHClientConfig(
      user: "nopass",
      port: "2222"
    )

    return (title, config)
  }
}

class TestProxyFactoryConfigurator: FileTranslatorFactory.Configurator {
  static let ProxyTestPath = "sftp:l:~/fps"

  struct TestProxyFactoryError: Error {}
  
  func sshConfig(host title: String) throws -> (String, SSH.SSHClientConfig) {
    if title == "l" {
      let config = SSHClientConfig(
        user: "nopass",
        port: "2222",
        proxyJump: "local"
      )
      return ("localhost", config)
    } else if title == "local" {
      let config = SSHClientConfig(
        user: "nopass",
        port: "2222"
      )
      return ("localhost", config)
    }

    throw TestProxyFactoryError()
  }
}
