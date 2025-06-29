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

struct FeedbackView: View {
    var body: some View {
      List {
        Section(header: Text("Community")) {
          HStack {
            Button {
              BKLinkActions.sendToDiscord()
            } label: {
              Label("Discord", systemImage: "link")
            }

            Spacer()
            Text("").foregroundColor(.secondary)
          }
          HStack {
            Button {
              BKLinkActions.send(toGitHub: nil)
            } label: {
              Label("Github", systemImage: "link")
            }

            Spacer()
            Text("/blinksh").foregroundColor(.secondary)
          }
          HStack {
            Button {
              BKLinkActions.sendToTwitter()
            } label: {
              Label("Twitter", systemImage: "link")
            }

            Spacer()
            Text("@BlinkShell").foregroundColor(.secondary)
          }
          HStack {
            Button {
              BKLinkActions.sendToReddit()
            } label: {
              Label("Reddit", systemImage: "link")
            }
            Spacer()
            Text("r/BlinkShell").foregroundColor(.secondary)
          }
        }

        Section(footer:Text("Support development by making Blink 5 stars!")) {
          HStack {
            Button {
              BKLinkActions.sendToAppStore()
            } label: {
              Label("Rate Blink", systemImage: "star")
            }

            Spacer()
            Text("App Store").foregroundColor(.secondary)
          }
        }
      }
      .listStyle(.grouped)
      .navigationTitle("Feedback")
    }
}
