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


import Foundation
import SwiftUI
import LocalAuthentication

struct SettingsView: View {

  @EnvironmentObject private var _nav: Nav
  @State private var _biometryType = LAContext().biometryType
  @State private var _blinkVersion = UIApplication.flowConsoleShortVersion() ?? ""
  @State private var _iCloudSyncOn = BKUserConfigurationManager.userSettingsValue(forKey: BKUserConfigiCloud)
  @State private var _autoLockOn = BKUserConfigurationManager.userSettingsValue(forKey: BKUserConfigAutoLock)
  @State private var _xCallbackUrlOn = BLKDefaults.isXCallBackURLEnabled()
  @State private var _defaultUser = BLKDefaults.defaultUserName() ?? ""
  @StateObject private var _entitlements: EntitlementsManager = .shared

  var body: some View {
    List {

      Section("Version") {
        HStack {
          Label("Flow Console (Free)", systemImage: "terminal")
          Spacer()
          Text("Open Source")
            .foregroundColor(.secondary)
        }
      }
      Section("Connect") {
        Row {
          Label("Keys & Certificates", systemImage: "key")
        } details: {
          KeyListView()
        }
        Row {
          Label("Hosts", systemImage: "server.rack")
        } details: {
          HostListView()
        }
        Row {
          Label("Default Agent", systemImage: "key.viewfinder")
        } details: {
          DefaultAgentSettingsView()
        }
        RowWithStoryBoardId(content: {
          HStack {
            Label("Default User", systemImage: "person")
            Spacer()
            Text(_defaultUser).foregroundColor(.secondary)
          }
        }, storyBoardId: "BKDefaultUserViewController")
      }

      Section("Terminal") {
        RowWithStoryBoardId(content: {
          Label("Appearance", systemImage: "paintpalette")
        }, storyBoardId: "BKAppearanceViewController")
        Row {
          Label("Keyboard", systemImage: "keyboard")
        } details: {
          KBConfigView(config: KBTracker.shared.loadConfig())
        }
        RowWithStoryBoardId(content: {
          Label("Smart Keys", systemImage: "keyboard.badge.ellipsis")
        }, storyBoardId: "BKSmartKeysConfigViewController")
        Row {
          Label("Notifications", systemImage: "bell")
        } details: {
          BKNotificationsView()
        }
#if targetEnvironment(macCatalyst)
        Row {
          Label("Gestures", systemImage: "rectangle.and.hand.point.up.left.filled")
        } details: {
          GesturesView()
        }
#endif
      }

      Section("Configuration") {
        Row {
          Label("Bookmarks", systemImage: "bookmark")
        } details: {
          BookmarkedLocationsView()
        }

        Row {
          Label("Snips", systemImage: "chevron.left.square")
        } details: {
          SnippetsConfigView()
        }

        RowWithStoryBoardId(content: {
          HStack {
            Label("iCloud Sync", systemImage: "icloud")
            Spacer()
            Text(_iCloudSyncOn ? "On" : "Off").foregroundColor(.secondary)
          }
        }, storyBoardId: "BKiCloudConfigurationViewController")

        RowWithStoryBoardId(content: {
          HStack {
            Label("Auto Lock", systemImage: _biometryType == .faceID ? "faceid" : "touchid")
            Spacer()
            Text(_autoLockOn ? "On" : "Off").foregroundColor(.secondary)
          }
        }, storyBoardId: "BKSecurityConfigurationViewController")
        RowWithStoryBoardId(content: {
          HStack {
            Label("X Callback Url", systemImage: "link")
            Spacer()
            Text(_xCallbackUrlOn ? "On" : "Off").foregroundColor(.secondary)
          }
        }, storyBoardId: "BKXCallBackUrlConfigurationViewController")
      }

      Section("Get in touch") {
        Row {
          Label("Support", systemImage: "book")
        } details: {
          SupportView()
        }
        Row {
          Label("Community", systemImage: "bubble.left")
        } details: {
          FeedbackView()
        }
        // HStack {
        //   Button {
        //     BKLinkActions.sendToAppStore()
        //   } label: {
        //     Label("Rate Blink", systemImage: "star")
        //   }

        //   Spacer()
        //   Text("App Store").foregroundColor(.secondary)
        // }
      }

      Section("About") {
        RowWithStoryBoardId(content: {
          HStack {
            Label("About", systemImage: "questionmark.circle")
            Spacer()
            Text(_blinkVersion).foregroundColor(.secondary)
          }
        }, storyBoardId: "BKAboutViewController")
      }
      
      Section("Legal") {
        Button {
          // Open your project's privacy policy URL
          if let url = URL(string: "https://github.com/your-repo/flow-console/blob/main/PRIVACY.md") {
            UIApplication.shared.open(url)
          }
        } label: {
          HStack {
            Label("Privacy Policy", systemImage: "link")
            Spacer()
          }
        }
        
        Button {
          // Open your project's terms/license URL  
          if let url = URL(string: "https://github.com/your-repo/flow-console/blob/main/LICENSE") {
            UIApplication.shared.open(url)
          }
        } label: {
          HStack {
            Label("License (GPL-3.0)", systemImage: "link")
            Spacer()
          }
        }
      }
    }
    .onAppear {
      _iCloudSyncOn = BKUserConfigurationManager.userSettingsValue(forKey: BKUserConfigiCloud)
      _autoLockOn = BKUserConfigurationManager.userSettingsValue(forKey: BKUserConfigAutoLock)
      _xCallbackUrlOn = BLKDefaults.isXCallBackURLEnabled()
      _defaultUser = BLKDefaults.defaultUserName() ?? ""

    }
    .listStyle(.grouped)
    .navigationTitle("Settings")

  }
}

