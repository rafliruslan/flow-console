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


class SearchTextInput: UITextField, UITextFieldDelegate {
  override var keyCommands: [UIKeyCommand]? {
    return _keyCommands
  }

  var _keyCommands: [UIKeyCommand] = []
  
  override init(frame: CGRect) {
    let escape = UIKeyCommand(
      input: UIKeyCommand.inputEscape,
      modifierFlags: [],
      action: #selector(SearchTextInput.close))
    let ctrlN = UIKeyCommand(
      input: "n", modifierFlags: .control,
      action: #selector(SearchTextInput.nextSnippet)
    )
    let ctrlP = UIKeyCommand(
      input: "p", modifierFlags: .control,
      action: #selector(SearchTextInput.prevSnippet)
    )
    
    let ctrlDown = UIKeyCommand(
      input: UIKeyCommand.inputDownArrow, modifierFlags: .control,
      action: #selector(SearchTextInput.nextSnippet)
    )
    let ctrlUp = UIKeyCommand(
      input: UIKeyCommand.inputUpArrow, modifierFlags: .control,
      action: #selector(SearchTextInput.prevSnippet)
    )
    let up = UIKeyCommand(
      input: UIKeyCommand.inputDownArrow, modifierFlags:  [],
      action: #selector(SearchTextInput.nextSnippet)
    )
    let down = UIKeyCommand(
      input: UIKeyCommand.inputUpArrow, modifierFlags: [],
      action: #selector(SearchTextInput.prevSnippet)
    )
    let ctrlJ = UIKeyCommand(
      input: "j", modifierFlags: .control,
      action: #selector(SearchTextInput.nextSnippet)
    )
    let ctrlK = UIKeyCommand(
      input: "k", modifierFlags: .control,
      action: #selector(SearchTextInput.prevSnippet)
    )
    let tab = UIKeyCommand(
      input: "\t", modifierFlags: [],
      action: #selector(SearchTextInput.nextSnippet)
    )
    let shiftTab = UIKeyCommand(
      input: "\t", modifierFlags: .shift,
      action: #selector(SearchTextInput.prevSnippet)
    )
//    let enter = UIKeyCommand(
//      input: "\r", modifierFlags: [],
//      action: #selector(SearchTextInput.enterEditCreateMode)
//    )
//    let enter2 = UIKeyCommand(
//      input: "\n", modifierFlags: [],
//      action: #selector(SearchTextInput.enterEditCreateMode)
//    )
    let cmdEnter = UIKeyCommand(
      input: "\r", modifierFlags: .command,
      action: #selector(SearchTextInput.insertRawSnippet)
    )
    let cmdShiftC = UIKeyCommand(
      input: "c", modifierFlags: [.command, .shift],
      action: #selector(SearchTextInput.copyRawSnippet)
    )
    
    self._keyCommands = [
      escape, ctrlN, ctrlJ, ctrlP, ctrlK, ctrlUp, ctrlDown, up, down, tab, shiftTab,
// NOTE: textFieldShouldReturn is used for software kb compatibility
//      enter, enter2,
      cmdEnter, cmdShiftC
    ]
    
    super.init(frame: frame)
    
    self.addTarget(self, action: #selector(textChanged), for: UIControl.Event.editingChanged)
    
    for cmd in self._keyCommands {
      cmd.wantsPriorityOverSystemBehavior = true
    }
    
    self.font = UIFont.systemFont(ofSize: 24, weight: .regular)
    
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    label.font = self.font
    label.text = "< "
    
    
    self.leftView = label
    self.leftViewMode = .always

    self.delegate = self
    
    self.autocapitalizationType = .none
    self.autocorrectionType = .no
    self.inputAssistantItem.leadingBarButtonGroups = []
    self.inputAssistantItem.trailingBarButtonGroups = []
    self.smartDashesType = .no
    self.smartQuotesType = .no
    self.smartInsertDeleteType = .no
    self.spellCheckingType = .no
    self.setNeedsLayout()
  }
  
  @objc func textChanged() {
    self.model.updateWith(text: self.text ?? "")
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.enterEditCreateMode()
    return false
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    true
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // Forced to be defined before the TextInput can be used.
  var model: SearchModel! = nil  {
    didSet {
      if self.text != model.input {
        self.text = model.input
        self.setNeedsLayout()
      }
    }
  }
  
  @objc func nextSnippet() {
    model.selectNextSnippet()
  }
  
  @objc func prevSnippet() {
    model.selectPrevSnippet()
  }
  
  @objc func enterEditCreateMode() {
    model.editSelectionOrCreate()
  }
  
  @objc func insertRawSnippet() {
    model.insertRawSnippet()
  }
  
  @objc func copyRawSnippet() {
    model.copyRawSnippet()
  }
  
  @objc func close() {
    model.close()
  }
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(UIResponderStandardEditActions.pasteAndMatchStyle(_:)) {
      return false
    }
    return super.canPerformAction(action, withSender: sender)
  }
  
}


struct SearchView: UIViewRepresentable {
  @ObservedObject var model: SearchModel
  
  func makeUIView(context: UIViewRepresentableContext<Self>) -> SearchTextInput {
    // TODO Why not initializing the SearchTextInput with the provided model?
    // It would be better than the var model: Model! = nil
    let view = SearchTextInput() //SearchTextView.create(model: model)
    model.inputView = view
    return view
  }
  
  func updateUIView(_ uiView: SearchTextInput, context: UIViewRepresentableContext<Self>) {
    uiView.model = self.model
  }
}
