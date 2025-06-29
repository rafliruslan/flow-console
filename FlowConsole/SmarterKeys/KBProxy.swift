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

class KBProxy: UIView {
  private unowned var _kbView: KBView
  
  init(kbView: KBView) {
    _kbView = kbView
    super.init(frame: .zero)
  }
  
  required init?(coder: NSCoder) {
    return nil
  }
  
  private var _barButtonView: UIView? {
    // BarButtonItemView
    // AssistantButtonBarGroupView
    // View
    // AssistantButtonBarView -- defines safe width
    superview?.superview?.superview?.superview
  }
  
  private var _placeView: UIView? {
    // SystemInputAssistantView
    _barButtonView?.superview
  }
  
  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    if superview == nil {
      _kbView.isHidden = true
      return
    }
    setNeedsLayout()
  }
    
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    guard
      let placeView = _placeView,
      let barButtonView = _barButtonView,
      let _ = window
    else {
      _kbView.isHidden = true
      return
    }
    
    if placeView != _kbView.superview {
      placeView.addSubview(_kbView)
    }
    
    _kbView.isHidden = false
    
    placeView.bringSubviewToFront(_kbView)
    // Detecting dismiss kb icon
    var rightBottom = CGPoint(x: bounds.width, y: bounds.height)
    rightBottom = convert(rightBottom, to: placeView)
    
    var bKBframe = placeView.bounds
    
    var hardwareKBAttached = false
    if bKBframe.size.width - rightBottom.x > 58 /* better check? */ {
      bKBframe.size.width -= (bKBframe.size.width - rightBottom.x) - 6
      hardwareKBAttached = true
    }
//    var traits = _kbView.traits
    
//    traits.isHKBAttached = hardwareKBAttached
//    traits.isPortrait = win.bounds.width < win.bounds.height
//    debugPrint("KBProxy isPortatit", traits.isPortrait)
    
//    _kbView.traits = traits
    _kbView.safeBarWidth = barButtonView.frame.width
    _kbView.frame = bKBframe
  }
}
