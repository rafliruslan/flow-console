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

@testable import FlowConsoleFiles

class LocalFilesTests: XCTestCase {
  var cancellableBag: [AnyCancellable] = []
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
  }
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testDirectory() throws {
    let f = Local()
    let expectation = self.expectation(description: "Local")
    
    f.directoryFilesAndAttributes()
      .assertNoFailure()
      .sink { items in
        XCTAssertTrue(items.count > 0)
        dump(items)
        expectation.fulfill()
      }.store(in: &cancellableBag)
    
    wait(for: [expectation], timeout: 1)
  }
  
  func testWalk() throws {
    let f = Local()
    let dirWalk = self.expectation(description: "Regular directory")
    
    // Absolute
    f.walkTo("/Users")
      .assertNoFailure()
      .sink { dir in
        XCTAssertTrue(dir.current == "/Users", "Current dir is \(dir.current)")
        dirWalk.fulfill()
      }.store(in: &cancellableBag)
    
    wait(for: [dirWalk], timeout: 1)
    
    // No permissions
    let noPermWalk = self.expectation(description: "No permission")
    f.walkTo("/tmp/inaccessible")
      .catch { err -> Just<Translator> in
        let err = err as! LocalFileError
        XCTAssertTrue(err.msg == "Permission denied.", "Received \(err)")
        return Just(f)
      }.sink { dir in
        XCTAssertTrue(dir.current == "/Users/carlos")
        noPermWalk.fulfill()
      }.store(in: &cancellableBag)
    
    wait(for: [noPermWalk], timeout: 1)
    
    // Relative
    let relativeWalk = self.expectation(description: "Relative walk")
    f.walkTo("carlos")
      .assertNoFailure()
      .sink { dir in
        XCTAssertTrue(dir.current == "/Users/carlos", "Current dir is \(dir.current)")
        relativeWalk.fulfill()
      }.store(in: &cancellableBag)
    
    wait(for: [relativeWalk], timeout: 1)
  }
  
  func testFileRead() throws {
    self.continueAfterFailure = false
    // For SFTP it will be useful to have the channel reachable, and then stop it through a timer to test the reconnect.
    let f = Local()
    let expectation = self.expectation(description: "Buffer Complete")
    
    // TODO Explicitely close the file or do it once it gets
    // dumped.
    f.walkTo("/Users/carlos/mosh.pkg")
      .flatMap { $0.open(flags: O_RDONLY) }
      .flatMap { $0.read(max: SSIZE_MAX) }
      .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case .failure(let error as LocalFileError):
          XCTFail(error.msg)
        case .failure(let error):
          XCTFail("Unknown error \(error)")
        }
      },
      receiveValue: { data in
        XCTAssertFalse(data.count <= 0, "Nothing received")
      }).store(in: &cancellableBag)
    
    waitForExpectations(timeout: 15, handler: nil)
    
    // TODO close file
    //file.close()
  }
  
  func testFileWriteTo() throws {
    self.continueAfterFailure = false
    // For SFTP it will be useful to have the channel reachable, and then stop it through a timer to test the reconnect.
    let f = Local()
    let expectation = self.expectation(description: "Buffer Complete")
    let buffer = MemoryBuffer(fast: true)
    
    // TODO Explicitely close the file or do it once it gets
    // dumped.
    f.walkTo("/Users/carlos/Xcode_12.0.1.xip")
      .flatMap { $0.open(flags: O_RDONLY) }
      .flatMap { ($0 as! WriterTo).writeTo(buffer) }
      .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
          XCTAssertTrue(buffer.count == 11210638916, "Data copied does not match.")
          expectation.fulfill()
        case .failure(let error as LocalFileError):
          XCTFail(error.msg)
        case .failure(let error):
          XCTFail("Unknown error \(error)")
        }
      },
      receiveValue: { wroteBytes in
        print(wroteBytes)
        XCTAssertFalse(wroteBytes <= 0, "Nothing received")
      }).store(in: &cancellableBag)
    
    waitForExpectations(timeout: 15, handler: nil)
  }
  
  // WriteToWriter
  // Hash check for result
  func testFileWriteToWriter() throws {
    self.continueAfterFailure = false
    // For SFTP it will be useful to have the channel reachable, and then stop it through a timer to test the reconnect.
    let f = Local()
    let dst = f.clone()
    let expectation = self.expectation(description: "Buffer Complete")
    var written = 0
    // TODO Explicitely close the file or do it once it gets
    // dumped.
    f.walkTo("/Users/carlos/Xcode_12.0.1.xip")
      .flatMap { $0.open(flags: O_RDONLY) }
      .flatMap { srcFile -> AnyPublisher<Int, Error> in
        return dst.create(name: "Docker-copy.dmg", mode: 0o644)
          .flatMap { dstFile in
            return (srcFile as! WriterTo).writeTo(dstFile)
          }.eraseToAnyPublisher()
      }.sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
          XCTAssertTrue(written == 11210638916, "Data copied does not match.")
          expectation.fulfill()
        case .failure(let error as LocalFileError):
          XCTFail(error.msg)
        case .failure(let error):
          XCTFail("Unknown error \(error)")
        }
      },
      receiveValue: { wroteBytes in
        written += wroteBytes
        print("Written \(written)")
        XCTAssertFalse(wroteBytes <= 0, "Nothing received")
      }).store(in: &cancellableBag)
    
    waitForExpectations(timeout: 1500, handler: nil)
  }
  
  func testWstat() throws {
    let f = Local()
    let expectation = self.expectation(description: "Buffer Complete")
    
    f.walkTo("/tmp/file")
      .flatMap { file -> AnyPublisher<Bool, Error> in
        let attrs: [FileAttributeKey:Any] = [.name: "/Users/carloscabanero/file_test",
                                             .modificationDate: NSDate(timeIntervalSinceNow: -40000)]
        return file.wstat(attrs)
      }.sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
          expectation.fulfill()
        case .failure(let error as LocalFileError):
          XCTFail(error.msg)
        case .failure(let error):
          XCTFail("Unknown error \(error)")
        }
      },
      receiveValue: { XCTAssertTrue($0) }).store(in: &cancellableBag)
    
    waitForExpectations(timeout: 2, handler: nil)
  }
}

class MemoryBuffer: Writer {
  var count = 0
  let fast: Bool
  let queue: DispatchQueue
  
  init(fast: Bool) {
    self.fast = fast
    self.queue = DispatchQueue(label: "test")
  }
  
  func write(_ buf: DispatchData, max length: Int) -> AnyPublisher<Int, Error> {
    return Just(buf.count).print("Write Request").receive(on: self.queue).map { val in
      self.count += buf.count
      
      if !self.fast {
        //sleep(1)
        usleep(1000)
      }
      print("==== Wrote \(self.count)")
      return val
    }.mapError { $0 as Error }.eraseToAnyPublisher()
  }
}
