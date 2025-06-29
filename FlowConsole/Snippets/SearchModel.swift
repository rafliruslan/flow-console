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
import FlowConsoleSnippets
import UIKit
import SwiftUI

class SearchModel: ObservableObject {
  weak var rootCtrl: UIViewController? = nil
  weak var inputView: UIView? = nil

  var fuzzyResults = FuzzyAccumulator(query: "")
  var searchResults = SearchAccumulator(query: "")
  var fuzzyCancelable: AnyCancellable? = nil
  var searchCancelable: AnyCancellable? = nil

  public var snippetContext: (any SnippetContext)? = nil

  var isFuzzyMode: Bool {
    self.searchResults.query.isEmpty
  }

  @Published var displayResults = [Snippet]() {
    didSet {
      if displayResults.isEmpty {
        self.selectedSnippetIdx = nil
      } else {
        self.selectedSnippetIdx = 0
      }
    }
  }

  @Published var selectedSnippetIdx: Int?

  @Published var currentSnippetName = ""
  @Published var editingSnippet: Snippet? = nil
  @Published var editingMode: TextViewEditingMode = .template
  @Published var newSnippetPresented = false
  @Published var indexProgress: SnippetsLocations.RefreshProgress = .none
  let defaultShellOutputFormatter = ShellOutputFormatter.lineBySemicolon

  let snippetsLocations: SnippetsLocations
  // Stored Index snapshot to search.
  var index: [Snippet] = []
  var indexFetchCancellable: Cancellable? = nil
  var indexProgressCancellable: Cancellable? = nil

  @Published private(set) var mode: SearchMode
  @Published private(set) var input: String {
    didSet {
      let splits = input.split(separator: " ", maxSplits: 1)
      guard
        self.mode != .general,
        let fuzzyQuery = splits.first
      else {
        self.fuzzyCancelable = nil
        self.searchCancelable = nil
        self.displayResults = []
        self.fuzzyResults.clear()
        self.searchResults.clear()
        return
      }
      var filterQuery = ""

      if splits.count == 2 {
        filterQuery = String(splits[1]).trimmingCharacters(in: .whitespacesAndNewlines)
      }

      let fQuery = String(fuzzyQuery)
//      fQuery.removeFirst()

      fuzzySearch(fQuery, filterQuery)
    }
  }



  init() throws {
    self.mode = .general
    self.input = ""

    self.snippetsLocations = try SnippetsLocations()

    self.indexFetchCancellable = self.snippetsLocations
      .indexPublisher
      // Refresh should happen on main thread, bc this is publishing changes.
      .receive(on: DispatchQueue.main)
      .sink(
      // Handle errors
      receiveCompletion: { _ in },
      receiveValue: { snippets in
        self.index = snippets
        self.input = { self.input }()
      })

    self.indexProgressCancellable = self.snippetsLocations
      .indexProgressPublisher
      .receive(on: DispatchQueue.main)
      .assign(to: \.indexProgress, on: self)
  }

  func updateWith(text: String) {
    self.mode = .insert
    self.input = text

//    if text.hasPrefix("<") {
//      self.mode = .insert
//    } else if text.hasPrefix("@") {
//      self.mode = .host
//    } else if text.hasPrefix("$") {
//      self.mode = .prompt
//    } else if text.hasPrefix(">") {
//      self.mode = .command
//    } else if text.hasPrefix("?") {
//      self.mode = .help
//    } else if text.hasPrefix("!") {
//      self.mode = .history
//    } else {
//      self.mode = .general
//    }

  }

  func insertRawSnippet() {
    // The snippet should only be selectable if the content is already there,
    // as it has already been part of a search and cached.
    guard let snippet = currentSelection,
          let content = try? snippet.content
    else {
      return
    }

    sendContentToReceiver(content: content)
  }

  func copyRawSnippet() {
    guard let snippet = currentSelection,
          let content = try? snippet.content
    else {
      return
    }

    UIPasteboard.general.string = content
    self.close()
  }

  func editSelectionOrCreate() {
    let snippet: Snippet
    if currentSelection == nil {
      if self.input.isEmpty {
        snippet = Snippet.scratch()
        self.editingMode = .code
      } else {
        openNewSnippet()
        return
      }
    } else {
      snippet = currentSelection!
      self.editingMode = .template
    }

    self.currentSnippetName = snippet.fuzzyIndex
    self.editingSnippet = snippet

    let textView = TextViewBuilder.createForSnippetEditing()
    let editorCtrl = EditorViewController(textView: textView, model: self)
    let navCtrl = UINavigationController(rootViewController: editorCtrl)
    navCtrl.modalPresentationStyle = .formSheet

    if let sheetCtrl = navCtrl.sheetPresentationController {
      sheetCtrl.prefersGrabberVisible = true
      sheetCtrl.prefersEdgeAttachedInCompactHeight = true
      sheetCtrl.widthFollowsPreferredContentSizeWhenEdgeAttached = true

      sheetCtrl.detents = [
        .custom(resolver: { context in
          120
        }),
        .medium(), .large()
      ]
      sheetCtrl.largestUndimmedDetentIdentifier = .large
    }
    rootCtrl?.present(navCtrl, animated: false)

  }

  func openNewSnippet() {
    self.newSnippetPresented = true
    let textView = TextViewBuilder.createForSnippetEditing()
    let editorCtrl = NewSnippetViewController(textView: textView, model: self)
    let navCtrl = UINavigationController(rootViewController: editorCtrl)
    navCtrl.modalPresentationStyle = .formSheet

    if let sheetCtrl = navCtrl.sheetPresentationController {
      sheetCtrl.prefersGrabberVisible = true
      sheetCtrl.prefersEdgeAttachedInCompactHeight = true
      sheetCtrl.widthFollowsPreferredContentSizeWhenEdgeAttached = true
      sheetCtrl.detents = [
        .medium(), .large()
      ]
      sheetCtrl.largestUndimmedDetentIdentifier = .large
    }
    rootCtrl?.present(navCtrl, animated: true)

  }

  @objc func sendContentToReceiver(content: String) {
    // NOTE Atm it is all shell content, at one point we should have different types.
    sendContentToReceiver(content: content, shellOutputFormatter: defaultShellOutputFormatter)
  }

  func sendContentToReceiver(content: String, shellOutputFormatter: ShellOutputFormatter) {
    let content = shellOutputFormatter.format(content)
    self.snippetContext?.providerSnippetReceiver()?.receive(content)
    self.editingSnippet = nil
    self.input = ""
    self.snippetContext?.dismissSnippetsController()
  }

  func close() {
    self.snippetContext?.dismissSnippetsController()
  }

  @objc func closeEditor() {
    self.editingSnippet = nil
    self.newSnippetPresented = false
    self.rootCtrl?.presentedViewController?.dismiss(animated: true)
  }

  func focusOnInput() {
    _ = self.inputView?.becomeFirstResponder()
  }

  func saveSnippet(newContent: String) throws {
    guard let snippet = self.editingSnippet else {
      return
    }

    try self.snippetsLocations.saveSnippet(folder: snippet.folder, name: snippet.name, content: newContent)
  }

  func deleteSnippet() throws {
    guard let snippet = editingSnippet else {
      return
    }

    try self.snippetsLocations.deleteSnippet(snippet: snippet)

    self.displayResults = []
    self.searchResults.clear()
    self.fuzzyResults.clear()
    self.input = ""
    self.editingSnippet = nil
  }

  func renameSnippet(newCategory: String, newName: String, newContent: String) throws {
    guard let snippet = self.editingSnippet else {
      return
    }
    let newSnippet = try
        self.snippetsLocations.renameSnippet(snippet: snippet, folder: newCategory, name: newName, content: newContent)
    self.displayResults = []
    self.searchResults.clear()
    self.fuzzyResults.clear()
    self.input = ""
    self.editingSnippet = newSnippet
  }

  func cleanString(str: String?) -> String {
    (str ?? "").lowercased()
      .replacingOccurrences(of: " ", with: "-")
      .replacingOccurrences(of: "/", with: "-")
      .replacingOccurrences(of: ".", with: "-")
      .replacingOccurrences(of: "~", with: "-")
      .replacingOccurrences(of: "\\", with: "-")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func refreshIndex() {
    self.snippetsLocations.refreshIndex(forceUpdate: true)
  }
}

public protocol SnippetReceiver {
  func receive(_ content: String)
}

public protocol SnippetContext {
  func presentSnippetsController()
  func dismissSnippetsController()
  func providerSnippetReceiver() -> (any SnippetReceiver)?
}

extension TermDevice: SnippetReceiver {
  public func receive(_ content: String) {
    self.view?.paste(content)
//    self.write(content)
  }
}

// MARK: Search

extension SearchModel {
  func fuzzySearch(_ query: String, _ searchQuery: String) {
    guard self.fuzzyResults.query != query
    else {
      self.fuzzyCancelable = nil // <- cancel fuzzy
      return search(query: searchQuery)
    }

    self.searchCancelable = nil

    if query.isEmpty {
      self.fuzzyCancelable = nil
      self.displayResults = []
      self.fuzzyResults.clear()
      self.searchResults.clear()
      return
    }

    let query = query.lowercased()

    self.fuzzyCancelable = fuzzyResults
      .chooseSource(query: query, wideIndex: self.index)
      .fuzzySearch(searchString: query, maxResults: ResultsLimit)
      .subscribe(on: DispatchQueue.global())
      .reduce(FuzzyAccumulator(query: query), FuzzyAccumulator.accumulate(_:_:))
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { completion in
        },
        receiveValue: { fuzzyResults in
          self.fuzzyResults = fuzzyResults
          self.search(query: searchQuery)
        })
  }

  func search(query: String) {
    if self.fuzzyResults.isEmpty {
      self.searchCancelable = nil
      self.displayResults = []
      return
    }

    if query.isEmpty {
      self.searchResults.clear()
      self.displayResults = self.fuzzyResults.snippets
      self.searchCancelable = nil
      return
    }

    self.searchCancelable = searchResults
      .chooseSource(query: query, wideIndex: self.fuzzyResults.snippets)
      .publisher
      .subscribe(on: DispatchQueue.global())
      .map { s in (s, Search(content: s.searchableContent, searchString: query)) }
      .reduce(SearchAccumulator(query: query), SearchAccumulator.accumulate(_:_:))
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { res in
          self.searchResults = res
          self.displayResults = res.snippets
        })
  }
}

// MARK: Snippet Selection
var generated: Bool = false

extension SearchModel {
  var currentSelection: Snippet? {
    if let idx = selectedSnippetIdx {
      return displayResults[idx]
    } else {
      return nil
    }

  }

  func onSnippetTap(_ snippet: Snippet) {
    if let index = self.displayResults.firstIndex(of: snippet) {
      self.selectedSnippetIdx = index
      self.editSelectionOrCreate()
    }
  }

  public func selectNextSnippet() {
    guard displayResults.count > 0  else {
      self.selectedSnippetIdx = nil
      return
    }
    guard let idx = self.selectedSnippetIdx else {
      self.selectedSnippetIdx = displayResults.count - 1
      return
    }

    self.selectedSnippetIdx = idx == 0 ? displayResults.count - 1 : idx - 1
  }

  public func selectPrevSnippet() {
    guard displayResults.count > 0  else {
      self.selectedSnippetIdx = nil
      return
    }
    guard let idx = self.selectedSnippetIdx else {
      self.selectedSnippetIdx = 0
      return
    }
    self.selectedSnippetIdx = (idx + 1 ) % displayResults.count
  }
}
