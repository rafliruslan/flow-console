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
import FlowConsoleSnippets
import FlowConsoleConfig
import Combine

// Works exclusively with the SearchModel, while being responsible for the
// locations, efficient caching and fetching of Snippets.
// Being a separate object gives us more flexibility to make this a Singleton, to cache it
// between multiple SearchModel usages, etc...
class SnippetsLocations {
  let locations: [SnippetContentLocation]
  // Default as the writing location.
  // NOTE In the future we may allow to re-define it, or to select it when storing.
  let defaultLocation: SnippetContentLocation
  var refreshCancellable: Cancellable? = nil
  
  enum RefreshProgress {
    case none
    case started
    case completed([LocationError]?)
  }
  // The main interface with the SearchModel. Provides the index whenever it has changed in any way.
  public let indexPublisher = CurrentValueSubject<[Snippet], Never>([])
  public let indexProgressPublisher = CurrentValueSubject<RefreshProgress, Never>(.none)
  
  public init() throws {
    let fm = FileManager.default
    
    let useiCloud = BLKDefaults.snippetsDefaultLocation() == .iCloud && fm.ubiquityIdentityToken != nil
    
    let dontUseBlinkSnippets = BLKDefaults.dontUseBlinkSnippetsIndex()
    
    let snippetsLocation = FlowConsolePaths.localSnippetsLocationURL()!
    let icloudSnippetsLocation = FlowConsolePaths.iCloudSnippetsLocationURL()
    let cachedSnippetsLocation = snippetsLocation.appending(path: ".cached")
   
    // Create main snippets location. Each location then is responsible for its structure.
    if !fm.fileExists(atPath: snippetsLocation.path()) {
      try fm.createDirectory(at: snippetsLocation, withIntermediateDirectories: true)
      if !dontUseBlinkSnippets {
        try fm.createDirectory(at: cachedSnippetsLocation, withIntermediateDirectories: true)
      }
    }
   
    if useiCloud, let location = icloudSnippetsLocation {
      if !fm.fileExists(atPath: location.path) {
        try fm.createDirectory(at: location, withIntermediateDirectories: true)
      }
    }
    
    // ".blink/snippets" for local
    // ".blink/snippets/.cached/com.github" for github
    // ".iCloud/snippets/ for icloud
    let defaultLocation = if useiCloud, let location = icloudSnippetsLocation {
      iCloudSnippets(from: location)
    } else {
      LocalSnippets(from: snippetsLocation)
    }

    // Locations are sorted by priority.
    var locations = [defaultLocation]

    if !dontUseBlinkSnippets {
      let blinkSnippetsLocation = try GitHubSnippets(owner: "blinksh", repo: "snippets", cachedAt: cachedSnippetsLocation)
      locations.append(blinkSnippetsLocation)
    }
    
    self.defaultLocation = defaultLocation
    self.locations = locations
    
    refreshIndex()
  }
  
  // If the ".locations" file changes, it will be read again
  // on "refresh". Or forced when the change happens.
  // Same with the .ignore file.
  // Locations ordering is preserved.
  public func refreshIndex(forceUpdate: Bool = false) {
    indexProgressPublisher.send(.started)

    var errors: [LocationError] = []
    let listSnippets: AnyPublisher<[(Int, [Snippet])], Never> =
    Publishers.MergeMany(locations.enumerated().map { (index, loc) in
        Deferred {
          Future {
            do {
              return (index, try await loc.listSnippets(forceUpdate: forceUpdate))
            } catch {
              errors.append(LocationError(id: loc.description, error: error))
              return (index, [])
            }
          }
        }
      })
      .assertNoFailure()
      .collect()
      .eraseToAnyPublisher()
    
    refreshCancellable = listSnippets.sink(
      receiveCompletion: { _ in self.indexProgressPublisher.send(.completed(errors.isEmpty ? nil : errors))},
      receiveValue: { snippetsList in
        let snippets = snippetsList.sorted(by: { $0.0 > $1.0 }).map { $0.1 }
        self.indexPublisher.send(Array(snippets.joined()))
      }
    )
  }
  
  public func saveSnippet(at location: SnippetContentLocation, folder: String, name: String, content: String) throws -> Snippet {
    let snippet = try location.saveSnippet(folder: folder, name: name, content: content)
    refreshIndex()
    return snippet
  }
  
  public func saveSnippet(folder: String, name: String, content: String) throws -> Snippet {
    
    return try saveSnippet(at: self.defaultLocation, folder: folder, name: name, content: content)
  }
  
  public func deleteSnippet(snippet: Snippet) throws {
    try snippet.store.deleteSnippet(folder: snippet.folder, name: snippet.name)
    // Remove from the index manually
    var index = indexPublisher.value
    index.removeAll(where: { $0 == snippet })
    indexPublisher.send(index)
  }
  
  public func renameSnippet(snippet: Snippet, folder: String, name: String, content: String) throws -> Snippet {
    // If we cannot write at the location, we store on default
    let store = snippet.store.isReadOnly ? defaultLocation : snippet.store
    if !snippet.store.isReadOnly {
      try self.deleteSnippet(snippet: snippet)
    }
    return try self.saveSnippet(at: store, folder: folder, name: name, content: content)
  }
}

extension Future where Failure == Error {
    convenience init(operation: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let output = try await operation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}

struct LocationError: Error, Identifiable {
  var id: String
  let error: Error
  var localizedDescription: String { error.localizedDescription }
}
