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
import UIKit

import SwiftUI
import Runestone
import TreeSitterBashRunestone


class EditorViewController: UIViewController, TextViewDelegate, UINavigationItemRenameDelegate {
  func navigationItem(_: UINavigationItem, didEndRenamingWith title: String) {}
  
  func navigationItemShouldBeginRenaming(_: UINavigationItem) -> Bool { true }
  
  func navigationItem(_: UINavigationItem, willBeginRenamingWith suggestedTitle: String, selectedRange: Range<String.Index>) -> (String, Range<String.Index>) {
    // preselect name part
    let parts = suggestedTitle.split(separator: "/", maxSplits: 1)
    if parts.count == 2 {
      return (suggestedTitle, suggestedTitle.range(of: String(parts[1]))!)
    } else {
      return (suggestedTitle, suggestedTitle.range(of: suggestedTitle)!)
    }
  }
  
  func navigationItem(_: UINavigationItem, shouldEndRenamingWith title: String) -> Bool {
    let str = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if str.hasPrefix("/") || !str.contains("/") || str.hasSuffix("/") {
      return false
    }

    let parts = title.split(separator: "/", maxSplits: 1)
    let category = model.cleanString(str: String(parts[0]))
    let name = model.cleanString(str:String(parts[1])) + ".sh"

    do {
      try model.renameSnippet(newCategory: category, newName: name, newContent: self.textView.text)
      return true
    } catch {
      showAlert(msg: "\(error)")
      return false
    }
  }

  func textViewDidBeginEditing(_ textView: TextView) {
    updateUIMode(textView)
  }

  func setNextTemplateTokenRanges(textView: TextView) {
    let text = textView.text
    let nextTokenRangeIndex: String.Index
    if let range = self.templateTokenRanges.first {
      nextTokenRangeIndex = Range(range, in: textView.text)!.upperBound
    } else {
      nextTokenRangeIndex = text.startIndex
    }
    
    if nextTokenRangeIndex < text.endIndex,
      let range = text[nextTokenRangeIndex...].range(of: #"\$\{[^\}]+\}"#, options: .regularExpression) {
      let token = String(text[range])
      let nextTokenRanges = text.ranges(of: token).map { NSRange($0, in: text) }
      self.templateTokenRanges = nextTokenRanges
      highlightTemplateTokenRanges(textView)
      let range = nextTokenRanges[0]
      textView.selectedTextRange =  textView.textRange(from: range)
    } else {
      completeTemplates()
    }
  }

  @objc func completeTemplates() {
    model.editingMode = .code
    updateUIMode(self.textView)
  }

  func updateUIMode(_ textView: TextView) {
    if model.editingMode == .template {
      self.textView.selectionHighlightColor = .systemYellow.withAlphaComponent(0.3)
      self.textView.selectionBarColor = .systemYellow.withAlphaComponent(0.8)
      self.textView.insertionPointColor = .systemYellow.withAlphaComponent(0.8)
      self.textView.returnKeyType = .next
      self.navigationItem.rightBarButtonItem =
        UIBarButtonItem(
          title: "Complete", style: .done, target: self, action: #selector(completeTemplates)
        )
      self.setNextTemplateTokenRanges(textView: textView)
    } else if model.editingMode == .code {
      self.textView.selectionHighlightColor = .blinkTint.withAlphaComponent(0.3)
      self.textView.selectionBarColor = .blinkTint.withAlphaComponent(0.8)
      self.textView.insertionPointColor = .blinkTint.withAlphaComponent(0.8)
      textView.highlightedRanges = []
      model.editingMode = .code
      textView.returnKeyType = .default
      let sendWithNewlineOptions = [
        UIAction(title: "Raw", handler: {_ in
          self.model.sendContentToReceiver(content: textView.text, shellOutputFormatter: .raw)
        }),
        UIAction(title: "Block", handler: {_ in
          self.model.sendContentToReceiver(content: textView.text, shellOutputFormatter: .block)
        }),
        UIAction(title: "B/E", handler: {_ in
          self.model.sendContentToReceiver(content: textView.text, shellOutputFormatter: .beginEnd)
        }),
        UIAction(title: "Semicolon", handler: {_ in
          self.model.sendContentToReceiver(content: textView.text, shellOutputFormatter: .lineBySemicolon)
        })
      ]

      self.navigationItem.rightBarButtonItems =
        [
         UIBarButtonItem(
          title: "Send", style: .done, target: self, action: #selector(send)
        ),
         UIBarButtonItem(
          image: UIImage(systemName: "paperplane.fill"),
          primaryAction: nil,
          menu: UIMenu(title: "Send as", children: sendWithNewlineOptions)
        ),]
    }
  }

  func textViewDidChangeSelection(_ textView: TextView) {
    // We could use this to trigger a search for underlying template.
    // But this would make the textview work unnecessarily.
    // We could also compare with the template ranges alone.
  }

  func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if self.acceptReplace || model.editingMode == .code {
      return true
    }

    // Check if a Tab or Enter was pressed, in which case, switch to "next token".
    if text == "\t" || text == "\n" {
      setNextTemplateTokenRanges(textView: textView)
      return false
    }

    guard let templateEditingRange = (templateTokenRanges.first {
      return $0.lowerBound <= range.lowerBound && $0.upperBound >= range.upperBound
    }) else {
      return false
    }

    // Replace all appearances in templateTokenRanges.
    // Move the templateTokenRanges to accommodate for the introduced text.
    var newTemplateTokenRanges: [NSRange] = []
    let editingLocationOffset  = range.lowerBound - templateEditingRange.lowerBound
    let newTokenRangeLength = templateEditingRange.length + text.count - range.length
    var accummulatedPositionOffset = 0

    self.acceptReplace = true
    defer {
      self.acceptReplace = false
    }
    templateTokenRanges.forEach {
      let replacementRange = NSRange(location: accummulatedPositionOffset + $0.location + editingLocationOffset, length: range.length)
      
      textView.replace(replacementRange, withText: text)

      // this will force rerendering of all highlights
      // textView.text = textView.text.replacingCharacters(in: Range(replacementRange, in: textView.text)!, with: text)
      let newTokenRange = NSRange(location: accummulatedPositionOffset + $0.location, length: newTokenRangeLength)
      newTemplateTokenRanges.append(newTokenRange)
      accummulatedPositionOffset += newTokenRangeLength - $0.length

      if templateEditingRange == $0 {
        textView.selectedRange = NSRange(location: newTokenRange.lowerBound + editingLocationOffset + text.count, length: 0)
      }
    }

    templateTokenRanges = newTemplateTokenRanges
    highlightTemplateTokenRanges(textView)
    textViewDidChange(textView)
    return false
  }

  func highlightTemplateTokenRanges(_ textView: TextView) {
    var num = 0

    let highlightedRanges = templateTokenRanges.map {
      num += 1
      return HighlightedRange(id: "templateToken-\(num)", range: $0, color: textView.theme.markedTextBackgroundColor)
    }

    textView.highlightedRanges = highlightedRanges
  }
  
  var textView: TextView
  var model: SearchModel
  var templateTokenRanges: [NSRange]
  var acceptReplace: Bool
  
  var _keyCommands: [UIKeyCommand] = []
  
  init(textView: TextView, model: SearchModel) {
    self.textView = textView
    self.model = model
    self.templateTokenRanges =  [NSRange]()
    self.acceptReplace = false
    super.init(nibName: nil, bundle: nil)
    self.textView.editorDelegate = self
    
    _keyCommands = [
      UIKeyCommand(input: "\r", modifierFlags: .command, action: #selector(send)),
      UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(cancel))
    ]
    for cmd in _keyCommands {
      cmd.wantsPriorityOverSystemBehavior = true
    }
  }
  
  override var keyCommands: [UIKeyCommand] {
    get {
      _keyCommands
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    self.view.backgroundColor = UIColor.systemBackground
    self.view.addSubview(textView)
    if let snippet = model.editingSnippet,
       let content = try? snippet.content {
      textView.text = content
      self.title = snippet.fuzzyIndex
    } else {
      textView.text = ""
    }

    self.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel)
    self.navigationItem.leftBarButtonItem?.target = self
    self.navigationItem.leftBarButtonItem?.action = #selector(cancel)
    self.navigationItem.style = .editor

    // For scratch, we disable special options
    // Ideally, a "Save as" would allow to rename scratch somewhere else, but we cannot change it.
    if model.editingSnippet?.name == "scratch" {
      return
    }
    self.navigationItem.renameDelegate = self
    self.navigationItem.titleMenuProvider = { suggestions in
      var finalMenuElements = suggestions

      finalMenuElements.append(
        UICommand(
          title: "Save",
          image: UIImage(systemName: "folder"),
          action: #selector(self.saveSnippet)
        )
      )
      finalMenuElements.append(
        UICommand(
          title: "Delete",
          image: UIImage(systemName: "trash"),
          action: #selector(self.deleteSnippet),
          attributes: .destructive
        )
      )
      return UIMenu(children: finalMenuElements)
    }
  }
  
  @objc func saveSnippet() {
    do {
      try model.saveSnippet(newContent: self.textView.text)
    } catch {
      showAlert(msg: "\(error)")
    }
  }

  @objc func deleteSnippet() {
    do {
      try model.deleteSnippet()
      model.closeEditor()
    } catch {
      showAlert(msg: "\(error)")
    }
  }
  
  @objc func cancel() {
    model.closeEditor()
  }
  
  @objc func send() {
    model.sendContentToReceiver(content: textView.text)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let ins = self.systemMinimumLayoutMargins
    textView.frame = self.view.bounds.insetBy(dx: ins.leading, dy: ins.top)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    _ = textView.becomeFirstResponder()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.model.closeEditor()
  }
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(deleteSnippet) {
      // TODO: check location
      return true
    }
    return super.canPerformAction(action, withSender: sender)
  }
  
  func showAlert(msg: String) {
    let ctrl = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
    ctrl.addAction(UIAlertAction(title: "Ok", style: .default))
    self.present(ctrl, animated: true)
  }
}
