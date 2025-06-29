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


import SwiftUI
import SSH

struct ImportKeyView: View {
  @ObservedObject var state: ImportKeyObservable
  
  let onCancel: () -> Void
  let onSuccess: () -> Void
  
  var body: some View {
    List {
      Section(
        header: Text("NAME"),
        footer: Text("Default key must be named `id_\(state.keyType.lowercased().replacingOccurrences(of: "-", with: "_"))`")
      ) {
        FixedTextField(
          "Enter a name for the key",
          text: $state.keyName,
          id: "keyName",
          nextId: "keyComment",
          autocorrectionType: .no,
          autocapitalizationType: .none
        )
      }
      
      Section(header: Text("COMMENT (OPTIONAL)")) {
        FixedTextField(
          "Comment for your key",
          text: $state.keyComment,
          id: "keyComment",
          returnKeyType: .continue,
          onReturn: {
            if state.saveKey() {
              onSuccess()
            }
          },
          autocorrectionType: .no,
          autocapitalizationType: .none
        )
      }
      
      Section(
        header: Text("INFORMATION"),
        footer: Text("Blink creates PKCS#8 public and private keys, with AES 256 bit encryption. Use \"ssh-copy-id [name]\" to copy the public key to the server.")
      ) { }
    }
    .listStyle(GroupedListStyle())
    .navigationBarItems(
      leading: Button("Cancel", action: onCancel),
      trailing: Button("Import") {
        if state.saveKey() {
          onSuccess()
        }
      }
      .disabled(!state.isValid)
    )
    .navigationBarTitle("Import \(state.keyType) Key")
    .alert(errorMessage: $state.errorMessage)
  }
}

class ImportKeyObservable: ObservableObject {
  let key: SSHKey;
  let keyType: String
  @Published var keyName: String
  @Published var keyComment: String
  @Published var errorMessage = ""
  
  var isValid: Bool {
    !keyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  init(key: SSHKey, keyName: String, keyComment: String) {
    self.key = key
    self.keyType = key.sshKeyType.shortName
    self.keyName = keyName
    self.keyComment = keyComment
  }
  
  func saveKey() -> Bool {
    errorMessage = ""
    let keyID = keyName.trimmingCharacters(in: .whitespacesAndNewlines)
    let comment = keyComment.trimmingCharacters(in: .whitespacesAndNewlines)
    
    do {
      if keyID.isEmpty {
        throw KeyUIError.emptyName
      }
      
      if BKPubKey.withID(keyID) != nil {
        throw KeyUIError.duplicateName(name: keyID)
      }
      
      try BKPubKey.addKeychainKey(id: keyID, key: key, comment: comment)
      
    } catch {
      errorMessage = error.localizedDescription
      return false
    }

    return true
  }
}
