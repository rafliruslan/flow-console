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
import CoreData


class MigrationAddSnippetsShortcut: MigrationStep {
  var version: Int { get { 1620 } }
  
  func execute() throws {
   
    guard KBTracker.shared.kbAlreadyConfigured() else {
      // user still uses default configuration
      return
    }
    
    let cfg = KBTracker.shared.loadConfig()
    let contains = cfg.shortcuts.contains { shortcut in
      switch shortcut.action {
      case KeyBindingAction.command(Command.snippetsShow): return true;
      default: return false;
      }
    }
    
    if contains {
      // user already configured snippets show action
      return
    }
    
    cfg.shortcuts.append(KeyShortcut.snippetsShowShortcut)
    KBTracker.shared.saveAndApply(config: cfg)
    
  }

}
