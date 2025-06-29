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
import FileProviderUI

class DocumentActionViewController: FPUIActionExtensionViewController {
  
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var actionTypeLabel: UILabel!
  @IBOutlet weak var doneButton: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    doneButton.layer.cornerRadius = 10
    doneButton.layer.masksToBounds = true
  }
  
  override func prepare(forAction actionIdentifier: String, itemIdentifiers: [NSFileProviderItemIdentifier]) {
    //identifierLabel?.text = actionIdentifier
    actionTypeLabel?.text = "Custom action"
    self.dismiss(animated: true, completion: {
      self.extensionContext.completeRequest()
      if itemIdentifiers.isEmpty {
        return
      }
      let identifier = BlinkItemIdentifier(itemIdentifiers[0])
      guard let rootPath = identifier.rootPath else {
        return
      }
      
      // rootPath: ssh:host:root_folder
      let components = rootPath.split(separator: ":")
      let remoteProtocol = components[0]
      
      var codeURL: URL
      if remoteProtocol == "local" {
        codeURL = URL(string: "vscode://local")!
        codeURL.appendPathComponent(components[1...].joined(separator: "/"))
        codeURL.appendPathComponent(identifier.path)
      } else {
        codeURL = URL(string: "vscode://sftp/\(components[1])")!
        codeURL.appendPathComponent(components[2...].joined(separator: "/"))
        codeURL.appendPathComponent(identifier.path)
      }
      // Open the URL
      self.extensionContext.open(codeURL)
    })
  }
  
  override func prepare(forError error: Error) {
    errorLabel?.text = error.localizedDescription
    actionTypeLabel?.text = "Authenticate"
  }
  
  @IBAction func doneButtonTapped(_ sender: Any) {
    // Perform the action and call the completion block. If an unrecoverable error occurs you must still call the completion block with an error. Use the error code FPUIExtensionErrorCode.failed to signal the failure.
    extensionContext.completeRequest()
  }
  
}


struct BlinkItemIdentifier {
  let path: String
  let encodedRootPath: String
  
  var rootPath: String? {
    guard let rootData = Data(base64Encoded: encodedRootPath),
          let rootPath = String(data: rootData, encoding: .utf8) else {
      return nil
    }
    return rootPath
  }
  // <encodedRootPath>/path/to, name = filename. -> <encodedRootPath>/path/to/filename
  init(parentItemIdentifier: BlinkItemIdentifier, filename: String) {
    self.encodedRootPath = parentItemIdentifier.encodedRootPath
    self.path = (parentItemIdentifier.path as NSString).appendingPathComponent(filename)
  }
  
  // <encodedRootPath>/path/to/filename
  init(_ identifier: NSFileProviderItemIdentifier) {
    let parts = identifier.rawValue.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
    self.encodedRootPath = parts[0]
    if parts.count > 1 {
      self.path = parts[1]
    } else {
      self.path = ""
    }
  }
}
