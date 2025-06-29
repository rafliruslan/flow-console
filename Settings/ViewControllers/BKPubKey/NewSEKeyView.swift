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


import SwiftUI
import SSH

struct NewSEKeyView: View {
  let onCancel: () -> Void
  let onSuccess: () -> Void
  
  @StateObject private var _state = NewSEKeyObservable()
  
  var body: some View {
    List {
      Section(
        header: Text("NAME"),
        footer: Text("Default key must be named `id_ecdsa`")
      ) {
        FixedTextField(
          "Enter a name for the key",
          text: $_state.keyName,
          id: "keyName",
          nextId: "keyComment",
          autocorrectionType: .no,
          autocapitalizationType: .none
        )
      }
      
      Section(header: Text("COMMENT (OPTIONAL)")) {
        FixedTextField(
          "Comment for your key",
          text: $_state.keyComment,
          id: "keyComment",
          returnKeyType: .continue,
          onReturn: _createKey,
          autocorrectionType: .no,
          autocapitalizationType: .none
        )
      }
      
      Section(
        header: Text("INFORMATION"),
        footer: Text("A Secure Enclave key is a hardware stored key that is isolated from the rest of the system. Note this type of private key cannot be read or copied, making it more difficult to become compromised.")
      ) { }
    }
    .listStyle(GroupedListStyle())
    .navigationBarItems(
      leading: Button("Cancel", action: onCancel),
      trailing: Button("Create", action: _createKey)
      .disabled(!_state.isValid)
    )
    .navigationBarTitle("New Secure Enclave Key")
    .alert(errorMessage: $_state.errorMessage)
    .onAppear(perform: {
      FixedTextField.becomeFirstReponder(id: "keyName")
    })
  }
  
  private func _createKey() {
    if _state.createKey() {
      onSuccess()
    }
  }
}

fileprivate class NewSEKeyObservable: ObservableObject {
  
  @Published var keyName = ""
  @Published var keyComment = "\(BLKDefaults.defaultUserName() ?? "")@\(UIDevice.getInfoType(fromDeviceName: BKDeviceInfoTypeDeviceName) ?? "")"
  
  @Published var errorMessage = ""
  
  var isValid: Bool {
    !keyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  func createKey() -> Bool {
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
      
      try BKPubKey.addSEKey(id: keyID, comment: comment)
    } catch {
      errorMessage = error.localizedDescription
      return false
    }

    return true
  }
}
