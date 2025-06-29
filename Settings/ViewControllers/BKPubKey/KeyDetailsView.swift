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

struct KeyDetailsView: View {
  @State var card: BKPubKey
  
  let reloadCards: () -> ()
  
  @EnvironmentObject private var _nav: Nav
  @State private var _keyName: String = ""
  @State private var _certificate: String? = nil
  @State private var _originalCertificate: String? = nil
  @State private var _pubkeyLines = 1
  @State private var _certificateLines = 1
  
  @State private var _actionSheetIsPresented = false
  @State private var _filePickerIsPresented = false
  
  @State private var _errorMessage = ""
  
  @State private var _publicKeyCopied = false
  @State private var _certificateCopied = false
  @State private var _privateKeyCopied = false
  
  private func _copyPublicKey() {
    _publicKeyCopied = false
    
    UIPasteboard.general.string = card.publicKey
    withAnimation {
      _publicKeyCopied = true
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      withAnimation {
        _publicKeyCopied = false
      }
    }
  }
  
  private func _copyCertificate() {
    _certificateCopied = false
    UIPasteboard.general.string = _certificate ?? ""
    withAnimation {
      _certificateCopied = true
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      withAnimation {
        _certificateCopied = false
      }
    }
  }
  
  private var _saveIsDisabled: Bool {
    (card.id == _keyName && _certificate == _originalCertificate) || _keyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  private func _showError(message: String) {
    _errorMessage = message
  }
  
  private func _importCertificateFromClipboard() {
    do {
      guard
        let str = UIPasteboard.general.string,
        !str.isEmpty
      else {
        return _showError(message: "Pasteboard is empty")
      }
      
      guard let blob = str.data(using: .utf8) else {
        return _showError(message: "Can't convert to string with UTF8 encoding")
      }
      try _importCertificateFromBlob(blob)
    } catch {
      _showError(message: error.localizedDescription)
    }
  }
  
  private func _importCertificateFromFile(result: Result<URL, Error>) {
    do {
      let url = try result.get()
      guard
        url.startAccessingSecurityScopedResource()
      else {
        throw KeyUIError.noReadAccess
      }
      defer {
        url.stopAccessingSecurityScopedResource()
      }
      
      let blob = try Data(contentsOf: url, options: .alwaysMapped)
      
      try _importCertificateFromBlob(blob)
    } catch {
      _showError(message: error.localizedDescription)
    }
  }
  
  private func _importCertificateFromBlob(_ certBlob: Data) throws {
    guard
      let privateKey = card.loadPrivateKey(),
      let privateKeyBlob = privateKey.data(using: .utf8)
    else {
      return _showError(message: "Can't load private key")
    }
    
    _ = try SSHKey(fromFileBlob: privateKeyBlob, passphrase: "", withPublicFileCertBlob: SSHKey.sanitize(key: certBlob))
    
    _certificate = String(data: certBlob, encoding: .utf8)
  }
  
  private func _sharePublicKey(frame: CGRect) {
    let activityController = UIActivityViewController(activityItems: [card], applicationActivities: nil);
  
    activityController.excludedActivityTypes = [
      .postToTwitter, .postToFacebook,
      .assignToContact, .saveToCameraRoll,
      .addToReadingList, .postToFlickr,
      .postToVimeo, .postToWeibo
    ]

    activityController.popoverPresentationController?.sourceView = _nav.navController.view
    activityController.popoverPresentationController?.sourceRect = frame
    _nav.navController.present(activityController, animated: true, completion: nil)
  }
  
  private func _copyPrivateKey() {
    _privateKeyCopied = false
    LocalAuth.shared.authenticate(callback: { success in
      guard
        success,
        let privateKey = card.loadPrivateKey()
      else {
        return
      }
      UIPasteboard.general.string = privateKey
      withAnimation {
        _privateKeyCopied = true
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        withAnimation {
          _privateKeyCopied = false
        }
      }
    }, reason: "to copy private key to clipboard.")
  }
  
  private func _removeCertificate() {
    _certificate = nil
  }
  
  private func _deleteCard() {
    LocalAuth.shared.authenticate(callback: { success in
      if success {
        BKPubKey.removeCard(card: card)
        reloadCards()
        _nav.navController.popViewController(animated: true)
      }
    }, reason: "to delete key.")
  }
  
  private func _saveCard() {
    let keyID = _keyName.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
      if keyID.isEmpty {
        throw KeyUIError.emptyName
      }
      
      if let oldKey = BKPubKey.withID(keyID) {
        if oldKey !== _card.wrappedValue {
          throw KeyUIError.duplicateName(name: keyID)
        }
      }
      
      _card.wrappedValue.id = keyID
      _card.wrappedValue.storeCertificate(inKeychain: _certificate)
      
      BKPubKey.saveIDS()
      _nav.navController.popViewController(animated: true)
      self.reloadCards()
    } catch {
      _showError(message: error.localizedDescription)
    }
  }
  
  var body: some View {
    List {
      Section(
        header: Text("NAME"),
        footer: Text("Default key must be named `id_\(card.keyType?.lowercased().replacingOccurrences(of: "-", with: "_") ?? "")`")
      ) {
        FixedTextField(
          "Enter a name for the key",
          text: $_keyName,
          id: "keyName",
          nextId: "keyComment",
          autocorrectionType: .no,
          autocapitalizationType: .none
        )
      }
      
      Section(header: Text("Public Key")) {
        HStack {
          Text(card.publicKey).lineLimit(_pubkeyLines)
        }.onTapGesture {
          _pubkeyLines = _pubkeyLines == 1 ? 100 : 1
        }
        
        Button(action: _copyPublicKey, label: {
          HStack {
            Label("Copy", systemImage: "doc.on.doc")
            Spacer()
            Text("Copied").opacity(_publicKeyCopied ? 1.0 : 0.0)
          }
        })
        GeometryReader(content: { geometry in
          let frame = geometry.frame(in: .global)
          Button(action: { _sharePublicKey(frame: frame) }, label: {
            Label("Share", systemImage: "square.and.arrow.up")
          }).frame(width: frame.width, height: frame.height, alignment: .leading)
        })
      }
     
      if card.storageType == BKPubKeyStorageTypeKeyChain {
        if let certificate = _certificate {
          Section(header: Text("Certificate")) {
            HStack {
              Text(certificate).lineLimit(_certificateLines)
            }.onTapGesture {
              _certificateLines = _certificateLines == 1 ? 100 : 1
            }
            Button(action: _copyCertificate, label: {
              HStack {
                Label("Copy", systemImage: "doc.on.doc")
                Spacer()
                Text("Copied").opacity(_certificateCopied ? 1.0 : 0.0)
              }
            })
            Button(action: _removeCertificate, label: {
              Label("Remove", systemImage: "minus.circle")
            }).accentColor(.red)
          }
        } else {
          Section() {
            Button(
              action: { _actionSheetIsPresented = true },
              label: {
                Label("Add Certificate", systemImage: "plus.circle")
              }
            )
            .actionSheet(isPresented: $_actionSheetIsPresented) {
                ActionSheet(
                  title: Text("Add Certificate"),
                  buttons: [
                    .default(Text("Import from clipboard")) { _importCertificateFromClipboard() },
                    .default(Text("Import from a file")) { _filePickerIsPresented = true },
                    .cancel()
                  ]
                )
            }
          }
        }
        
        Section() {
          Button(action: _copyPrivateKey, label: {
            HStack {
              Label("Copy private key", systemImage: "doc.on.doc")
              Spacer()
              Text("Copied").opacity(_privateKeyCopied ? 1.0 : 0.0)
            }
          })
        }
      }
      
      Section() {
        Button(
          action: _deleteCard,
          label: { Label("Delete", systemImage: "trash").foregroundColor(.red)}
        )
          .accentColor(.red)
      }
    }
    .listStyle(GroupedListStyle())
    .navigationTitle("Key Info")
    .navigationBarItems(
      trailing: Button("Save", action: _saveCard)
      .disabled(_saveIsDisabled)
    )
    .fileImporter(
      isPresented: $_filePickerIsPresented,
      allowedContentTypes: [.text, .data, .item],
      onCompletion: _importCertificateFromFile
    )
    .onAppear(perform: {
      _keyName = card.id
      _certificate = card.loadCertificate()
      _originalCertificate = _certificate
    })
    .alert(errorMessage: $_errorMessage)
  }
}
