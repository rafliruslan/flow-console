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
import FlowConsoleConfig

import SwiftUI

fileprivate func openLocationInFilesApp(location: BKSnippetDefaultLocation) {
  let path: String = { if location == .iCloud, let path = FlowConsolePaths.iCloudSnippetsLocationURL()?.relativePath {
    return path
  } else {
    return FlowConsolePaths.localSnippetsLocationURL()!.relativePath
  } }()
  
  let fm = FileManager.default
  if !fm.fileExists(atPath: path) {
    try? fm.createDirectory(atPath: path, withIntermediateDirectories: true)
  }
  let actualURL = URL(string: "shareddocuments:/\(path)")!
  UIApplication.shared.open(actualURL)
}

struct SnippetsConfigView: View {
  @State var useBlinkIndex = !BLKDefaults.dontUseBlinkSnippetsIndex()
  @State var defaultStorage = BLKDefaults.snippetsDefaultLocation()
  @State var iCloudEnabled = FileManager.default.ubiquityIdentityToken != nil
  
  var body: some View {
    List {
      
      Section(
        header: Text("Locations"),
        footer: Text(iCloudEnabled ? "Open in [Files.app](https://files.app)" : "iCloud is disabled on this device.")
          .environment(\.openURL, OpenURLAction { url in
            openLocationInFilesApp(location: self.defaultStorage)
            return .discarded
          })
      ) {
        if iCloudEnabled {
          Picker(selection: $defaultStorage, label: Text("Default Location")) {
            Label("iCloud Drive", systemImage: "icloud")
            //            .labelStyle(.iconOnly)
              .tag(BKSnippetDefaultLocation.iCloud)
            Label(DeviceInfo.shared().onMyDevice(), systemImage: DeviceInfo.shared().deviceIcon())
            //            .labelStyle(.iconOnly)
              .tag(BKSnippetDefaultLocation.onDevice)
          }
        } else {
          HStack {
            Text("Default Location")
            Spacer()
            Label(DeviceInfo.shared().onMyDevice(), systemImage: DeviceInfo.shared().deviceIcon())
          }
        }
      }
      Section(
        header: Text("Sources"),
        footer: Text("Use public [collection](https://github.com/blinksh/snippets) of snippets. PRs are welcomed.")
      ) {
        Toggle("Blink Snips Index", isOn: $useBlinkIndex)
      }
    }
    .listStyle(GroupedListStyle())
    .navigationBarTitle("Snips")
    .onDisappear(perform: {
      BLKDefaults.setDontUseBlinkSnippetsIndex(!useBlinkIndex)
      BLKDefaults.setSnippetsDefaultLocation(defaultStorage)
      BLKDefaults.save()
    })
  }
}
