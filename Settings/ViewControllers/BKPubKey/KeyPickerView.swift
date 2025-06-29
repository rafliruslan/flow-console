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

fileprivate struct CardRow: View {
  let key: BKPubKey
  let isChecked: Bool
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(key.id)
        Text(key.keyType ?? "").font(.footnote)
      }.contentShape(Rectangle())
      Spacer()
      Checkmark(checked: isChecked)
    }.contentShape(Rectangle())
  }
}

struct KeyPickerView: View {
  @Binding var currentKey: [String]
  @EnvironmentObject private var _nav: Nav
  @State private var _list: [BKPubKey] = BKPubKey.all()
  let multipleSelection: Bool
  
  var body: some View {
    List {
      HStack {
        Text("None")
        Spacer()
        Checkmark(checked: currentKey.isEmpty)
      }
      .contentShape(Rectangle())
      .onTapGesture {
        _selectKey("")
      }
      ForEach(_list, id: \.tag) { key in
        CardRow(key: key, isChecked: currentKey.contains { key.id == $0 })
          .onTapGesture {
            _selectKey(key.id)
          }
      }
    }
    .listStyle(InsetGroupedListStyle())
    .navigationTitle("Select a Key")
    .onAppear {
      // Make sure the key selection can only be based on the canonical list.
      currentKey = currentKey.filter { key in _list.contains(where: { $0.id == key }) }
    }
  }
  
  private func _selectKey(_ key: String) {
    if multipleSelection {
      if key.isEmpty {
        currentKey = []
      } else if let idx = currentKey.firstIndex(of: key) {
        currentKey.remove(at: idx)
      } else {
        currentKey.append(key)
      }
    } else {
      if key.isEmpty {
        currentKey = []
      } else {
        currentKey = [key]
      }
      _nav.navController.popViewController(animated: true)
    }
  }
}
