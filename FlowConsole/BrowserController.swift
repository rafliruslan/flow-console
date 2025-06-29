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
import WebKit

@objc public class BrowserController: UIViewController {
  
  @objc public var webView: WKWebView? = nil {
    didSet {
      oldValue?.removeFromSuperview()
      if let web = webView {
        view.addSubview(web)
      }
    }
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.leftBarButtonItems = [
      UIBarButtonItem(
        image: UIImage(systemName: "arrow.left"),
        style: .plain,
        target: self,
        action: #selector(_goBack)
      ),
      UIBarButtonItem(
        image: UIImage(systemName: "arrow.right"),
        style: .plain,
        target: self,
        action: #selector(_goForward)
      ),
    ]
    
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(
        barButtonSystemItem: .close,
        target: self,
        action: #selector(_close)
      ),
      UIBarButtonItem(
        barButtonSystemItem: .refresh,
        target: self,
        action: #selector(_reload)
      ),
      UIBarButtonItem(
        image: UIImage(systemName: "safari"),
        style: .plain,
        target: self,
        action: #selector(_openBrowser)
      ),
    ]
    
  }
  
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    webView?.frame = self.view.bounds
  }
  
  @objc func _goBack() {
    webView?.goBack()
  }
  
  @objc func _goForward() {
    webView?.goForward()
  }
  
  @objc func _reload() {
    webView?.reloadFromOrigin()
  }
  
  @objc func _close() {
    self.dismiss(animated: true) {
        
    }
  }
  
  @objc func _openBrowser() {
    if let url = webView?.url {
      blink_openurl(url)
    }
  }
}
