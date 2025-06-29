//////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Copyright (C) 2016-2021 Flow Console Project
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

@testable import FlowConsoleFiles

class CopyFilesTests: XCTestCase {
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testCopyFileFrom() throws {
    self.continueAfterFailure = false
    var totalWritten: UInt64 = 0
    let expectFileCopied = self.expectation(description: "File Copied")
    
    var c = Local().cloneWalkTo("/Users/carloscabanero/tmp").flatMap { destDir -> CopyProgressInfoPublisher in
      return Local().cloneWalkTo("/Users/carloscabanero/iPad_Pro_Spring_2021_15.0.ipsw")
        .flatMap { destDir.copy(from: [$0]) }
        .eraseToAnyPublisher()
    }.sink(receiveCompletion: { completion in
      switch completion {
      case .finished:
        expectFileCopied.fulfill()
      case .failure(let error):
        XCTFail("Crash \(error)")
      }
    }, receiveValue: { report in
      totalWritten += report.written
    })
    
    
    wait(for: [expectFileCopied], timeout: 1000)
    
    XCTAssertTrue(totalWritten == 6191846351)
  }
  
  func testCopyFrom() throws {
    self.continueAfterFailure = false
    let expectStructureCopied = self.expectation(description: "Structure Copied")
    
    var c = Local().cloneWalkTo("/tmp/test").flatMap { destDir -> CopyProgressInfoPublisher in
      return Local().cloneWalkTo("/Users/carloscabanero/tmp")
        .flatMap { destDir.copy(from: [$0]) }
        .eraseToAnyPublisher()
    }.sink(receiveCompletion: { completion in
      switch completion {
      case .finished:
        expectStructureCopied.fulfill()
      case .failure(let error):
        XCTFail("Crash \(error)")
      }
    }, receiveValue: { report in
      print("\(report.name) - \(report.written) - \(report.size)")
    })
    
    wait(for: [expectStructureCopied], timeout: 1000)
  }
}
