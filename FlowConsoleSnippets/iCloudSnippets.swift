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


import Foundation

public class iCloudSnippets: LocalSnippets {
  private let _fileManager: FileManager
  private let _downloadQueue: DispatchQueue
  
  public override init(from sourcePathURL: URL) {
    self._fileManager = FileManager.default
    self._downloadQueue = DispatchQueue.global()
    super.init(from: sourcePathURL)
  }
  
  public override func listSnippets(forceUpdate: Bool = false) async throws -> [Snippet] {
    try _fileManager.startDownloadingUbiquitousItem(at: self.sourcePathURL)
    return try await super.listSnippets(forceUpdate: forceUpdate)
  }
 
  public override func readDescription(folder: String, name: String) throws -> String {
    let url = snippetLocation(folder: folder, name: name)
    let iCloudUrl = url.appendingPathExtension("icloud")
    if _fileManager.fileExists(atPath: iCloudUrl.path) {
      _downloadQueue.async {
        // NOTE: if we try to read first line, .icloud will be still there
        _ = try? String(contentsOf: url)
      }
      return ""
    }
    return url.readFirstLineOfContent() ?? ""
  }
  
}

