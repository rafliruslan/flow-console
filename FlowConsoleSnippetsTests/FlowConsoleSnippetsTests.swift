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
@testable import FlowConsoleSnippets

extension URL: FuzzySearchable {
  public var fuzzyIndex: String {
    self.path
  }
}

extension URL: AdaptiveSearchable {
  public var searchableContent: String {
    let content = try? String(contentsOf: self)
    return content ?? ""
  }
  

}


final class BlinkSnippetsTests: XCTestCase {
  func sampleFilesIndex() -> [URL] {
    var files: [URL] = []
    let sourceDirURL = URL(fileURLWithPath: "/Users/carloscabanero/dev/blink-build")
    if let enumerator = FileManager.default.enumerator(
      at: sourceDirURL,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles, .skipsPackageDescendants]
    ) {
      for case let fileURL as URL in enumerator {
        do {
          let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
          if fileAttributes.isRegularFile! {
            files.append(fileURL)
          }
        } catch { print(error, fileURL) }
      }
      print("Number of files \(files.count)")
    }

    return files
  }
  
  func testAdaptiveSearch() throws {
    // The index can be built by a different algorithm, so we decide what goes there.
    // let index = ["one two": "a",
    //              "two three": "b",
    //              "three four": "c",
    //              "five one": "d",
    //              "two four": "e",
    //              "four five": "f"]
    
    // let matches = AdaptiveSearchMatch(within: index, searchString: "fiv o")
    // print(matches)
    
    //var matches: [URL] = []
    //      measure {
    let matches = self.sampleFilesIndex()
      .adaptiveSearchMatch(searchString:  "b tas")
    // print("Number of matches \(matches.count)")
    //      }
    
    measure {
      for (f, _) in matches {
        let ranges = Search(content: try! String(contentsOf: f), searchString: "Message")
        if ranges.count > 0 {
          print("\(f.path) - \(ranges)")
        }
      }
    }
    
    // first token  - matches
    // second token - matches
    // Figure out what token has changed. Then perform search from it.
    //      matches = matches.refine(searchString: "on f", previous: matches).collect()
    
    // I do not need the full structure.
    //matches = AdaptiveSearch(within: index, searchString: "on f", previous: matches).collect()
    
    // matches.each()
    // This would require to keep the index and maybe the searchString may completely change.
    // Also, if a search is aborted, the state of this is unknown.
    // matches.refine("")
  }

  func testSnippets() async throws {
    // Setup different snippet locations.
    // Create an index from the snippets.
    // Perform a match on the index.
    // Then from the matching snippets, perform a search.
    let local = LocalSnippets(from: URL(fileURLWithPath: "test-snippets"))
    
    // Who should be responsible to store snippets in this way?
    // What happens if the user imports a set of snippets that do not follow this convention.
    // We do not need to change anything on our side. The fuzzy algorithm could have special scores
    // for slashes, dashes and spaces. The title is decided by the storage.
    // We could potentially penalize spaces.
    // Or enforce them if we consider a snippet with special characters (spaces included) invalid.
    // try local.saveSnippet(folder: "general", name: "start-ssh-connection.sh.enc", content: "ssh host_name")
    
    // the pasteboard being a special location, we can afford a special way to store information.
    // try pasteboard.copy(content: "copied information")
    // then internally
    // try pasteboard.saveSnippet(folder: "", name: self.lastElement, content: "copied information")
    
    try local.saveSnippet(folder: "General", name: "Start SSH Connection.sh.enc", content: "ssh host_name")
    try local.saveSnippet(folder: "General", name: "Start SSH Connection.sh.enc", content: "ssh $host")
    
    let snippets = try await local.listSnippets()
    print(snippets)
    let index = Dictionary(uniqueKeysWithValues: snippets.lazy.map { ($0.indexable, $0) })
    
    try local.deleteSnippet(folder: "General", name: "Start SSH Connection.sh.enc")
  }

  func testSearch() throws {
    let filesIndex = self.sampleFilesIndex()
    
    let needle = "task"
    
    let expectFuzzyComplete = self.expectation(description: "Fuzzy Done")
    var results = 0
    var files: [URL] = []
    let c1 = filesIndex.fuzzySearch(searchString: needle, maxResults: 30).sink(
      receiveCompletion: { _ in
        expectFuzzyComplete.fulfill()
        print("Total results \(results)")
      },
      receiveValue: { val in
        print(val)
        files.append(val.0)
        results += 1
      }
    )
    
    wait(for: [expectFuzzyComplete], timeout: 5)
    
    // let expectSearchComplete = self.expectation(description: "Grep Search Done")
    let searchString = "Message fail"
    // I would do combine here, on a per file level.
    for fileURL in files {
      Search(content: try String(contentsOf: fileURL), searchString: searchString).forEach { (line, _) in
        print("\(fileURL) - \(line)")
      }
    }
  }
  
  func testMultilineRanges() {
    let result = Search(content:"""
    git config --global user.name "${first_name_last_name}"
    git config --global user.email "${email}"
    """, searchString: "use")
    for (line, ranges) in result {
      for range in ranges {
        (line as NSString).substring(with: range)
      }
    }
  }

  func testGitHubLocation() async throws {
    let location = try FileManager.default.url(for: .cachesDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
    let githubLocation = location.appending(path: "com.github")
    if FileManager.default.fileExists(atPath: githubLocation.path()) {
      try FileManager.default.removeItem(at: githubLocation)
    }
    let gh = try GitHubSnippets(owner: "blinksh", repo: "snippets", cachedAt: location)
//    try await gh.update(previous: nil)
//
//    print(try FileManager.default.contentsOfDirectory(at: location, includingPropertiesForKeys: nil))
//    XCTAssertTrue(FileManager.default.fileExists(atPath: location.appending(path: "com.github/blinksh-snippets").path()))
    
    // First refresh
    var snippets = try await gh.listSnippets()
    XCTAssertTrue(snippets.count > 0)
    var previousFetchData = try GitHubFetchData.read(forRepoAt: gh.location)!

    // Change timestamp and try again (new timestamp but same ETAG)
    let twoDaysBeforeFetch = GitHubFetchData(lastRequestDate: Date(timeIntervalSinceNow: (-3600 * 24) - 10), etag: previousFetchData.etag)
    try twoDaysBeforeFetch.save(forRepoAt: gh.location)
    snippets = try await gh.listSnippets()
    XCTAssertTrue(snippets.count > 0)
    previousFetchData = try GitHubFetchData.read(forRepoAt: gh.location)!
    XCTAssertFalse(previousFetchData.lastRequestDate == twoDaysBeforeFetch.lastRequestDate)
    XCTAssertTrue(previousFetchData.etag == twoDaysBeforeFetch.etag)
    
    // Change timestamp and ETAG. New download.
    let differentEtagFetch = GitHubFetchData(lastRequestDate: Date(timeIntervalSinceNow: (-3600 * 24) - 10), etag: "XXX")
    snippets = try await gh.listSnippets()
    XCTAssert(snippets.count > 0)
    previousFetchData = try GitHubFetchData.read(forRepoAt: gh.location)!
    XCTAssertTrue(differentEtagFetch.etag != previousFetchData.etag)
    let lastRequestDate = previousFetchData.lastRequestDate
    
    // Force update
    snippets = try await gh.listSnippets(forceUpdate: true)
    previousFetchData = try GitHubFetchData.read(forRepoAt: gh.location)!
    XCTAssertTrue(lastRequestDate != previousFetchData.lastRequestDate)
  }
    // func testGitHubLocation() throws {
      // // Setup a GitHub snippet location.
      // // Add a snippet to that location.
      // // If we give each location its own methods, then the snippets for each location
      // // will need a specific interface to work with that.
      // // A location can offer a specific interface and ways to traverse it, decide what we
      // // cache, etc...
      // let github = GitHubSnippets(at: repoURL)
      // try github.addFolder("blink").await

      // let snippets = try github.list()

      // github.addSnippet(folder, name, content)

      // // A snippet internally always have a URL from where we can read.
      // // It is like we did with the FileProvider.
      // // It is a better interface here than at the FP itself bc we have everything cached.

      // // On write, the snippet will notify its location of the change and trigger to the location.
      // // Update remote, then update local (simple 2PC). We assume local won't fail.
      // try snippet.write()

      // // On read, we could have a revision for the group, and update the cache.
      // // When can that check be triggered?
      // try snippet.read()
    // }
}

