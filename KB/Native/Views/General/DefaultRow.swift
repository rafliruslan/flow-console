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

struct DefaultRow<Details: View>: View {
  @Binding var title: String
  @Binding var description: String?
  var details: () ->  Details
  
  init(title: String, description: String? = nil, details: @escaping () -> Details) {
    _title = .constant(title)
    _description = .constant(description)
    self.details = details
  }
  
  init(title: Binding<String>, description: Binding<String?> = .constant(nil), details: @escaping () -> Details) {
    _title = title
    _description = description
    self.details = details
  }
  
  var body: some View {
    Row(content: {
      HStack {
        Text(self.title).foregroundColor(.primary)
        Spacer()
        Text(self.description ?? "").foregroundColor(.secondary)
      }
    }, details: self.details)
  }
}
