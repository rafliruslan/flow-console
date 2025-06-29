//////////////////////////////////////////////////////////////////////////////////
//
// F L O W  C O N S O L E
//
// Copyright (C) 2016-2019 Flow Console Project
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


import UIKit

class BlinkCommand: UIKeyCommand {
  var bindingAction: KeyBindingAction = .none
}

class KBWebView: KBWebViewBase {
  
  private var _loaded = false
  private(set) var webViewReady = false
  private(set) var blinkKeyCommands: [BlinkCommand] = []
  private(set) var allBlinkKeyCommands: [BlinkCommand] = []
  
  func configure(_ cfg: KBConfig) {
    _buildCommands(cfg)

    guard
      let data = try? JSONEncoder().encode(cfg),
      let json = String(data: data, encoding: .utf8)
    else {
      return
    }
    report("config", arg: json as NSString)
  }
  
  func _buildCommands(_ cfg: KBConfig) {
    
    self.blinkKeyCommands.removeAll()
    self.allBlinkKeyCommands.removeAll()
    
    cfg.shortcuts.forEach { shortcut in
      let cmd = BlinkCommand(
        title: "",
        image: nil,
        action: #selector(SpaceController._onBlinkCommand(_:)),
        input: shortcut.input,
        modifierFlags: shortcut.modifiers,
        propertyList: nil
      )
      cmd.bindingAction = shortcut.action
      
      allBlinkKeyCommands.append(cmd)
      
      if !shortcut.action.isCommand {
        blinkKeyCommands.append(cmd)
      }
    }
  }
  
  
  override var editingInteractionConfiguration: UIEditingInteractionConfiguration {
    return .none
  }
  
  func matchCommand(input: String, flags: UIKeyModifierFlags) -> (UIKeyCommand, UIResponder)? {
    var result: (UIKeyCommand, UIResponder)? = nil
    
    var iterator: UIResponder? = self
    
    // try first on space controller
    let cmd = allBlinkKeyCommands.first(
      where: {
        $0.input == input && $0.modifierFlags == flags
      }
    )
    
    if let cmd = cmd {
      while let responder = iterator {
        if let _ = responder as? SpaceController,
           let action = cmd.action,
           responder.canPerformAction(action, withSender: self) {
          return (cmd, responder)
        }
        iterator = responder.next
      }
    }
    
    iterator = self
    
    while let responder = iterator {
      if let cmd = responder.keyCommands?.first(
        where: {
          $0.input == input && $0.modifierFlags == flags
        }),
         let action = cmd.action,
         responder.canPerformAction(action, withSender: self)
      {
        result = (cmd, responder)
      }
      iterator = responder.next
    }

    return result
  }
  
  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    guard
      let key = presses.first?.key,
      let (cmd, responder) = matchCommand(input: key.charactersIgnoringModifiers, flags: key.modifierFlags),
      let action = cmd.action
    else {
      // Remap cmd+. from Escape back to cmd+.
      if let key = presses.first?.key,
         key.keyCode.rawValue == 55,
         key.characters == "UIKeyInputEscape"
      {
        self.reportToolbarPress(key.modifierFlags.union(.command), keyId: "190:0")
        return
      }
      super.pressesBegan(presses, with: event)
      return
    }
    
    responder.perform(action, with: cmd)
  }
  
  func contentView() -> UIView? {
    scrollView.subviews.first
  }
  
  func disableTextSelectionView() {
    let subviews = scrollView.subviews
    guard
      subviews.count > 2,
      let v = subviews[1].subviews.first
    else {
      return
    }
    NotificationCenter.default.removeObserver(v)
  }
  
  override func ready() {
    webViewReady = true
    super.ready()
    configure(KBTracker.shared.loadConfig())
  }
  
  private func _loadKB() {
    let bundle = Bundle.init(for: KBWebView.self)
    guard
      let path = bundle.path(forResource: "kb", ofType: "html")
    else {
      return
    }
    let url = URL(fileURLWithPath: path)
    loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
  }
  
  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    if window != nil && !_loaded {
      _loaded = true
      _loadKB()
    }
  }
}
