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

class KBKeyViewFlexible: KBKeyView {
  private var _textLayer = CATextLayer()
  
  override init(key: KBKey, keyDelegate: KBKeyViewDelegate) {
    super.init(key: key, keyDelegate: keyDelegate)
    
    _textLayer.string = key.shape.primaryText
    
    _textLayer.alignmentMode = .center
    _textLayer.allowsFontSubpixelQuantization = true
    _textLayer.opacity = 0
    layer.addSublayer(_textLayer)
    
    _setupColorsAndFonts()
    
    layer.rasterizationScale = traitCollection.displayScale
    layer.shouldRasterize = true
    layer.masksToBounds = true
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let kbSizes = keyDelegate.kbSizes
    let insets = kbSizes.key.insets.key
    let parentSize = bounds.inset(by: insets).size
    let center = CGPoint(x: parentSize.width * 0.5 + insets.left, y: parentSize.height * 0.5 + insets.top)
    _textLayer.frame = CGRect(origin: .zero, size: _textLayer.preferredFrameSize())
    _textLayer.position = center
  }
  
  private func _setupColorsAndFonts() {
    let scale = traitCollection.displayScale
    let font = UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: .medium)
    let fontSize = min(font.pointSize, 26)
    
    _textLayer.font = font
    _textLayer.fontSize = fontSize
    _textLayer.contentsScale = scale
    _textLayer.foregroundColor = UIColor.label.cgColor
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    _setupColorsAndFonts()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    _textLayer.opacity = 1
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    _textLayer.opacity = 0
    keyDelegate.keyViewTriggered(keyView: self, value: key.shape.primaryValue)
    super.touchesEnded(touches, with: event)
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    _textLayer.opacity = 0
    super.touchesCancelled(touches, with: event)
  }
  
}
