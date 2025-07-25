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

class KBAccessoryView: UIInputView {
  private let _kbView: KBView
  private var _heightContraint: NSLayoutConstraint? = nil
  
  init(kbView: KBView) {
    _kbView = kbView
    var size = _kbView.intrinsicContentSize
    size.width = 100
    super.init(frame: CGRect(origin: .zero, size: size), inputViewStyle: .keyboard)
    translatesAutoresizingMaskIntoConstraints = false
    allowsSelfSizing = true
    
    _heightContraint = self.heightAnchor.constraint(equalToConstant: size.height)
    _heightContraint?.isActive = true
    
    addSubview(_kbView)
  }
  
  required init?(coder: NSCoder) {
    return nil
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    var kbFrame = bounds
    kbFrame.size.height = _kbView.intrinsicContentSize.height
    _kbView.frame = kbFrame
  }
  
  override var intrinsicContentSize: CGSize {
    let h = _kbView.intrinsicContentSize.height + safeAreaInsets.bottom
    _heightContraint?.constant = h
    return CGSize(width: -1, height: h)
  }
}

extension KBAccessoryView: UIInputViewAudioFeedback {
  var enableInputClicksWhenVisible: Bool {
    return !BKUserConfigurationManager.userSettingsValue(forKey: BKUserConfigMuteSmartKeysPlaySound)
  }
}
