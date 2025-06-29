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
import Dispatch
import UIKit


fileprivate var attachedShortcuts: [UIKeyCommand] = []


//To rebuild a menu, call the setNeedsRebuild method. Call setNeedsRevalidate when you need the menu system to revalidate a menu.
@objc public class MenuController: NSObject {
  enum ShellMenu: String, CaseIterable {
    case windowNew
    case windowClose
    case tabNew
    case tabClose
    case configShow
  }

  enum EditMenu: String, CaseIterable {
    case clipboardCopy
    case clipboardPaste
    case selectionGoogle
    case selectionStackOverflow
    case selectionShare
  }
  
  enum ViewMenu: String, CaseIterable {
    case toggleKeyCast
    case zoomIn
    case zoomOut
    case zoomReset
  }
  
  enum WindowMenu: String, CaseIterable {
    case windowFocusOther
    case tabMoveToOtherWindow
    case tabNext
    case tabPrev
    case tabLast
  }

  override private init() {}
  
  @objc public class func buildMenu(with builder: UIMenuBuilder) {
    // We will embed our own textSize inside View, so just remove to avoid collisions.
    builder.remove(menu: .textSize)
    
    let kbConfig = KBTracker.shared.loadConfig()

    attachedShortcuts = []
    let shellMenuCommands:  [UICommand] = ShellMenu.allCases.map  { _generate(Command(rawValue: $0.rawValue)!, with: kbConfig) }
    let editMenuCommands:   [UICommand] = EditMenu.allCases.map   { _generate(Command(rawValue: $0.rawValue)!, with: kbConfig) }
      + Self.remainingStandardEditMenuCommands()
    let viewMenuCommands:   [UICommand] = ViewMenu.allCases.map   { _generate(Command(rawValue: $0.rawValue)!, with: kbConfig) }
    let windowMenuCommands: [UICommand] = WindowMenu.allCases.map { _generate(Command(rawValue: $0.rawValue)!, with: kbConfig) }

    builder.insertSibling(UIMenu(title: "Shell",
                                 image: nil,
                                 identifier: UIMenu.Identifier("sh.blink.blinkshell.menus.shellMenu"),
                                 options: [],
                                 children: shellMenuCommands), beforeMenu: .edit)
  
    // remove cmd+b, cmd+i and cmd+u
    builder.remove(menu: .textStyle)
    // remove cmd+t
    builder.remove(menu: .font)
//    builder.remove(menu: .help) - cmd+?
//    builder.remove(menu: .close)
//    builder.remove(menu: .hide)
//    builder.remove(menu: .edit)
//    builder.remove(menu: .textStylePasteboard)
//    builder.remove(menu: .spelling)
//    builder.remove(menu: .spellingPanel)
//    builder.remove(menu: .alignment)
//    builder.remove(menu: .format)
//    builder.remove(menu: .minimizeAndZoom)


    builder.replaceChildren(ofMenu: .standardEdit) { _ in editMenuCommands   }
    builder.replaceChildren(ofMenu: .view)         { _ in viewMenuCommands  }
    builder.replaceChildren(ofMenu: .window)       { _ in windowMenuCommands }
    
  }
  
  private class func _generate(_ command: Command, with kbConfig: KBConfig) -> UICommand {

    // For the action to be different, we are passing it as part of the PropertyList.
    // If the shortcut has already been assigned, then we define it as UICommand.
    if let shortcut = kbConfig.shortcuts.first(where: { s in // s.triggers(command)
      if case .command(let cmd) = s.action,
         case command = cmd
      {
        return true
      }
      return false
    })
    {
      // The same shortcut, or the same action, will make this crash with a
      // 'NSInternalInconsistencyException', reason: 'replacement menu has duplicate submenu,
      // command or key command, or a key command is missing input or action'.
      if !attachedShortcuts.contains(where: {
        $0.input == shortcut.input && $0.modifierFlags == shortcut.modifiers
      }) {
        let cmd =  UIKeyCommand(title: command.title,
                                action: #selector(SpaceController._onShortcut(_:)),
                                input: shortcut.input,
                                modifierFlags: shortcut.modifiers,
                                propertyList: ["Command": command.rawValue])

        if #available(iOS 15.0, *) {
          cmd.wantsPriorityOverSystemBehavior = true
        }
        
        
        attachedShortcuts.append(cmd)
        return cmd
      } else {
        // We will handle dups via pressesBegan, no need to alert user.
        
        // We notify the user and let the command go through as a UICommand
//        let alert = OwnAlertController(title: "Error building app menu", message: "The shortcut's '\(shortcut.title)' input is duplicated. This may prevent it from working. Please fix on Settings > Keyboard > Shortcuts", preferredStyle: .alert)
//        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
//        alert.addAction(ok)
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
//          alert.present(animated: true, completion: nil)
//        }
      }
    }
    return UICommand(
      title: command.title,
      image: nil,
      action: #selector(SpaceController._onShortcut(_:)),
      propertyList: ["Command": command.rawValue]
    )
  }
  
  // As we are rewriting the edit menu, if the standard sequences are not defined,
  // we add them here so they can go through the normal flow, and let our terminal map.
  private class func remainingStandardEditMenuCommands() -> [UICommand] {
    if ProcessInfo().isMacCatalystApp {
      return []
    }
    let copyCommand = UIKeyCommand(
      title: "",
      action: #selector(UIResponder.copy(_:)),
      input: "c",
      modifierFlags: .command,
      propertyList: nil
    )
    let cutCommand  = UIKeyCommand(
      title: "",
      action: #selector(UIResponder.cut(_:)),
      input: "x",
      modifierFlags: .command,
      propertyList: nil
    )
    let selectAllCommand =  UIKeyCommand(
      title: "",
      action: #selector(UIResponder.selectAll(_:)),
      input: "a",
      modifierFlags: .command,
      propertyList: nil
    )
    let toggleBoldCommand = UIKeyCommand(
      title: "",
      action: #selector(UIResponder.toggleBoldface(_:)),
      input: "b",
      modifierFlags: .command,
      propertyList: nil
    )
    let toggleItalicCommand = UIKeyCommand(
      title: "",
      action: #selector(UIResponder.toggleItalics(_:)),
      input: "i",
      modifierFlags: .command,
      propertyList: nil
    )
    let toggleUnderlineCommand = UIKeyCommand(
      title: "",
      action: #selector(UIResponder.toggleUnderline(_:)),
      input: "u",
      modifierFlags: .command,
      propertyList: nil
    )
    
    return [
      copyCommand,
      cutCommand,
      selectAllCommand,
      toggleBoldCommand, // from textStyle menu
      toggleItalicCommand,
      toggleUnderlineCommand
    ]
      .filter { shortcut in
        false == attachedShortcuts.contains(where: {
          $0.input == shortcut.input && $0.modifierFlags == shortcut.modifierFlags
        })
      }
  }
}

