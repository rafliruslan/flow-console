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

extension BKAgentForward: Hashable {
  var label: String {
    switch self {
    case BKAgentForwardNo: return "No"
    case BKAgentForwardConfirm: return "Confirm"
    case BKAgentForwardYes: return "Always"
    case _: return ""
    }
  }
  
  var hint: String {
    switch self {
    case BKAgentForwardNo: return "Do not forward the agent"
    case BKAgentForwardConfirm: return "Confirm each use of a key"
    case BKAgentForwardYes: return "Forward all keys always"
    case _: return ""
    }
  }

  static var all: [BKAgentForward] {
    [
      BKAgentForwardNo,
      BKAgentForwardConfirm,
      BKAgentForwardYes,
    ]
  }
}

struct AgentForwardPromptPickerView: View {
  @Binding var currentValue: BKAgentForward

  var body: some View {
    List {
      Section(footer: Text(currentValue.hint)) {
        ForEach(BKAgentForward.all, id: \.self) { value in
          HStack {
            Text(value.label).tag(value)
            Spacer()
            Checkmark(checked: currentValue == value)
          }
          .contentShape(Rectangle())
          .onTapGesture { currentValue = value }
        }
      }
    }
    .listStyle(InsetGroupedListStyle())
    .navigationTitle("Agent Forwarding")
  }
}
