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

struct SupportView: View {
  @EnvironmentObject private var _nav: Nav
  @State var displayWalkthrough = false

  var body: some View {
    List {
      Section(header: Text("Learn")) {
        HStack {
          Button { displayWalkthrough = true }
          label: {
            Label("Walkthrough", systemImage: "hand.tap")
          }
          Spacer()
          Text("").foregroundColor(.secondary)
        }
        HStack {
          Button {
            BKLinkActions.sendToDocumentation()
          } label: {
            Label("Documentation", systemImage: "book")
          }
          Spacer()
          Text("").foregroundColor(.secondary)
        }
      }
      Section(header: Text("Send Feedback")) {
        HStack {
          Button {
            BKLinkActions.send(toGitHub: "blink/discussions/new?category=support")
          } label: {
            Label("Ask a Question", systemImage: "questionmark.bubble")
          }

          Spacer()
          Text("").foregroundColor(.secondary)
        }
        HStack {
          Button {
            BKLinkActions.send(toGitHub: "blink/discussions/new?category=ideas")
          } label: {
            Label("Suggest a Feature", systemImage: "star.bubble")
          }

          Spacer()
          Text("").foregroundColor(.secondary)
        }

        HStack {
          Button {
            BKLinkActions.send(toGitHub: "blink/discussions")
          } label: {
            Label("Discussions", systemImage: "bubble")
          }

          Spacer()
          Text("Github").foregroundColor(.secondary)
        }

        HStack {
          Button {
            BKLinkActions.sendToDiscordSupport()
          } label: {
            Label("#support", systemImage: "ellipsis.bubble")
          }

          Spacer()
          Text("Discord").foregroundColor(.secondary)
        }
      }

      Section(header: Text("Internals")) {
        Button {
          UIPasteboard.general.string = "unlimited_user"
        } label: {
          Label("Copy User ID", systemImage: "doc.on.clipboard")
        }
      }
    }
      .listStyle(.grouped)
      .navigationTitle("Support")
      .sheet(isPresented: $displayWalkthrough) {
        WalkthroughWindow(urlHandler: blink_openurl, dismissHandler: { displayWalkthrough = false })
      }
  }
}

fileprivate struct WalkthroughWindow: View {
  let urlHandler: (URL) -> ()
  let dismissHandler: () -> ()

  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  var body: some View {
    VStack(spacing: 20) {
      Text("Flow Console Support")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Text("Free and Open Source Terminal")
        .font(.title2)
        .foregroundColor(.secondary)
      
      Text("Welcome to Flow Console, a completely free and open source terminal application for iPad.")
        .multilineTextAlignment(.center)
        .padding()
      
      Button("Get Started") {
        dismissHandler()
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(.black)
  }
}
