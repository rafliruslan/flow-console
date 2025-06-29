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

class KBSection {
  private var _keys: [KBKey] = []
  private var _filteredKeys: [KBKey] = []
  
  private var _views: [KBKeyView] = []
  var views: [KBKeyView] { _views }
  
  private var _traits: KBTraits = []
  
  init(keys: [KBKey]) {
    _keys = keys
  }

  func apply(traits: KBTraits, for view: UIView, keyDelegate: KBKeyViewDelegate) -> [KBKeyView] {
    // little optimization
    if _traits == traits {
      return _views
    }
    _traits = traits
    
    let filteredKeys = _keys.filter { $0.match(traits: traits) }
    let diff = filteredKeys.difference(from: _filteredKeys)
    
    if diff.isEmpty {
      return _views
    }
    
    _filteredKeys = filteredKeys
    
    for change in diff {
      switch change {
      case .remove(let offset, _, _):
        let keyView = _views[offset]
        keyView.removeFromSuperview()
        _views.remove(at: offset)
      case .insert(let offset, element: let key, _):
        let keyView = key.view(keyDelegate: keyDelegate)
        _views.insert(keyView, at: offset)
        view.addSubview(keyView)
      }
    }

    return _views
  }
}
