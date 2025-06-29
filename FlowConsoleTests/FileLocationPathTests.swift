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

import FlowConsoleCode

@testable import Blink


final class FileLocationPathTests: XCTestCase {
  let LocalRelativePath = "path/to/files"
  let LocalAbsolutePath = "/absolute/path/to/files"
  let LocalHomePath = "~/"

  let RemoteRelativePath = "sftp:host:path/to/files"
  let RemoteAbsolutePath = "sftp:host:/c:/path/to/files"
  // These should be untouched and canonicalized by Translator
  let RemoteHomePath = "user@host#2222:~/path/to/files"

  func testFileLocationPath() throws {
    // All locations should start with /

    let localPath = try! FileLocationPath(LocalRelativePath)
    XCTAssertTrue(localPath.proto == .local)
    // FM default path on tests is "/"
    XCTAssertTrue(localPath.filePath == "/path/to/files")
    let localPathURI = localPath.codeFileSystemURI!
    XCTAssertTrue(localPathURI == (try! URI(string: "blinkfs:/path/to/files")))

    let localAbsolutePath = try! FileLocationPath(LocalAbsolutePath)
    XCTAssertTrue(localAbsolutePath.proto == .local)
    XCTAssertTrue(localAbsolutePath.filePath == "/absolute/path/to/files")
    let localAbsolutePathURI = localAbsolutePath.codeFileSystemURI!
    XCTAssertTrue(localAbsolutePathURI == (try! URI(string: "blinkfs:/absolute/path/to/files")))

    let homePath = try! FileLocationPath(LocalHomePath)
    XCTAssertTrue(homePath.proto == .local)
    XCTAssertTrue(homePath.filePath == "/~")
    let homePathURI = homePath.codeFileSystemURI!
    XCTAssertTrue(homePathURI == (try! URI(string: "blinkfs:/~")))

    let emptyLocalPath = try! FileLocationPath("")
    XCTAssertTrue(emptyLocalPath.proto == .local)
    XCTAssertTrue(emptyLocalPath.filePath == "/")
    XCTAssertTrue(emptyLocalPath.codeFileSystemURI! == (try! URI(string: "blinkfs:/")))

    let remotePath = try! FileLocationPath(RemoteRelativePath)
    XCTAssertTrue(remotePath.proto == .sftp)
    XCTAssertTrue(remotePath.hostPath == "host")
    XCTAssertTrue(remotePath.filePath == "/~/path/to/files")
    let remotePathURI = remotePath.codeFileSystemURI!
    XCTAssertTrue(remotePathURI == (try! URI(string: "blinksftp://host/~/path/to/files")))

    let remoteAbsolutePath = try! FileLocationPath(RemoteAbsolutePath)
    XCTAssertTrue(remoteAbsolutePath.proto == .sftp)
    XCTAssertTrue(remoteAbsolutePath.hostPath == "host")
    XCTAssertTrue(remoteAbsolutePath.filePath == "/c:/path/to/files")
    let remoteAbsolutePathURI = remoteAbsolutePath.codeFileSystemURI!
    XCTAssertTrue(remoteAbsolutePathURI == (try! URI(string: "blinksftp://host/c:/path/to/files")))

    let remoteHomePath = try! FileLocationPath(RemoteHomePath)
    XCTAssertTrue(remoteHomePath.proto == nil)
    XCTAssertTrue(remoteHomePath.hostPath == "user@host#2222")
    XCTAssertTrue(remoteHomePath.filePath == "/~/path/to/files")
    let remoteHomeURI = remoteHomePath.codeFileSystemURI!
    XCTAssertTrue(remoteHomeURI == (try! URI(string: "blinksftp://user@host:2222/~/path/to/files")))

    let emptyRemoteHome = try! FileLocationPath("host:")
    XCTAssertTrue(emptyRemoteHome.proto == nil)
    XCTAssertTrue(emptyRemoteHome.hostPath == "host")
    XCTAssertTrue(emptyRemoteHome.filePath == "/~")
    XCTAssertTrue(emptyRemoteHome.codeFileSystemURI! == (try! URI(string: "blinksftp://host/~")))
  }
}
