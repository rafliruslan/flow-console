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

protocol KBKeyViewDelegate: class {
  func keyViewAskedToCancelScroll(keyView: KBKeyView)
  
  func keyViewOn(keyView: KBKeyView, value: KBKeyValue)
  func keyViewOff(keyView: KBKeyView, value: KBKeyValue)
  func keyViewTriggered(keyView: KBKeyView, value: KBKeyValue)
  func keyViewCancelled(keyView: KBKeyView)
  func keyViewCanGoOff(keyView: KBKeyView, value: KBKeyValue) -> Bool
  func keyViewTouchesBegin(keyView: KBKeyView, touches: Set<UITouch>)
  
  var kbSizes: KBSizes { get }
}

class KBKeyView: UIView {
  let key: KBKey
  private(set) var trackingTouch: UITouch? = nil
  
  open var shouldAutoRepeat: Bool { false }
  
  var isTracking: Bool {
    if let touch = trackingTouch {
      return touch.phase != .ended && touch.phase != .cancelled
    } else {
      return false
    }
  }
  
  unowned let keyDelegate: KBKeyViewDelegate
  
  init(key: KBKey, keyDelegate: KBKeyViewDelegate) {
    self.key = key
    self.keyDelegate = keyDelegate
    super.init(frame: .zero)
  }
  
  open var currentValue: KBKeyValue {
    key.shape.primaryValue
  }
  
  required convenience init?(coder: NSCoder) {
    return nil
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    trackingTouch = touches.first
    turnOn()
    keyDelegate.keyViewTouchesBegin(keyView: self, touches: touches)
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    guard
      let touch = trackingTouch,
      touches.contains(touch)
    else {
      return
    }
    turnOff()
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    guard
      let touch = trackingTouch,
      touches.contains(touch)
    else {
      return
    }
    turnOff()
    keyDelegate.keyViewCancelled(keyView: self)
  }
  
  
  override func layoutSubviews() {
    super.layoutSubviews()
    _updateLayerShapeMask()
  }
  
  private func _updateLayerShapeMask() {
    guard
      let shape = layer.mask as? CAShapeLayer,
      shape.frame != bounds
    else {
      return
    }

    let sizes = keyDelegate.kbSizes
    shape.path = UIBezierPath(roundedRect: bounds.inset(by: sizes.key.insets.key), cornerRadius: sizes.key.corner).cgPath
    shape.fillRule = .evenOdd
    shape.backgroundColor = UIColor.clear.cgColor
    shape.fillColor = UIColor.white.cgColor
  }
  
  open func turnOff() {
    backgroundColor = .clear
    trackingTouch = nil
    keyDelegate.keyViewOff(keyView: self, value: currentValue)
    setNeedsLayout()
  }
  
  open func turnOn() {
    if layer.mask == nil {
      layer.mask = CAShapeLayer()
      _updateLayerShapeMask()
    }
    
    backgroundColor = .tertiarySystemBackground
    
    keyDelegate.keyViewOn(keyView: self, value: currentValue)
    UIDevice.current.playInputClick()
  }
}


