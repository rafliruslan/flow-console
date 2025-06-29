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

import UIKit

class KBKeyViewSymbol: KBKeyView {
  var _imageView: UIImageView
  
  override init(key: KBKey, keyDelegate: KBKeyViewDelegate) {
    _imageView = UIImageView(
      image: UIImage(
        systemName: key.shape.primaryValue.symbolName ?? "questionmark.diamond"
      )
    )
    
    super.init(key: key, keyDelegate: keyDelegate)
    
    isAccessibilityElement = true
    accessibilityValue = key.shape.primaryValue.accessibilityLabel
    accessibilityTraits.insert(UIAccessibilityTraits.keyboardKey)
    
    let kbSizes = keyDelegate.kbSizes

    _imageView.contentMode = .center
    _imageView.preferredSymbolConfiguration = .init(pointSize: kbSizes.key.fonts.symbol,
                                                    weight: .regular)

    _imageView.tintColor = UIColor.label
    
    
    addSubview(_imageView)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    _imageView.frame = bounds.inset(by: keyDelegate.kbSizes.key.insets.symbol)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    if key.isModifier {
      self.backgroundColor = .white
      _imageView.tintColor = UIColor.darkText
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard
       let touch = trackingTouch,
       touches.contains(touch)
     else {
       super.touchesEnded(touches, with: event)
       return
     }
    
    guard
      keyDelegate.keyViewCanGoOff(keyView: self, value: key.shape.primaryValue)
    else {
      return
    }
    
    if !shouldAutoRepeat {
      keyDelegate.keyViewTriggered(keyView: self, value: key.shape.primaryValue)
    }
    super.touchesEnded(touches, with: event)
  }
  
  override var shouldAutoRepeat: Bool {
    switch key.shape.primaryValue {
    case .esc, .left, .right, .up, .down, .tab:
      return true
    default: return super.shouldAutoRepeat
    }
  }
  
  override func turnOff() {
    super.turnOff()
    _imageView.tintColor = UIColor.label
    if key.shape.primaryValue.isModifier {
      accessibilityTraits.remove([.selected])
    }
  }
  
  override func turnOn() {
    super.turnOn()
    if key.shape.primaryValue.isModifier {
      accessibilityTraits.insert([.selected])
    }
  }
  
}
