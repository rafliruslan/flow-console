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

struct StuckView: View {
  private var _emojies = ["😱", "🤪", "🧐", "🥺", "🤔", "🤭", "🙈", "🙊"]
  var keyCode: KeyCode
  var dismissAction: () -> ()
  
  init(keyCode: KeyCode, dismissAction: @escaping () -> ()) {
    self.keyCode = keyCode
    self.dismissAction = dismissAction
  }
  
  var body: some View {
      VStack {
        HStack {
          Spacer()
          Button("Close", action: dismissAction)
        }.padding()
        Spacer()
        Text(_emojies.randomElement() ?? "🤥").font(.system(size: 60)).padding(.bottom, 26)
        Text("Stuck key detected.").font(.headline).padding(.bottom, 30)
        Text("Press \(keyCode.fullName) key").font(.system(size: 30))
        Spacer()
        HStack {
          Text("Also, please")
          Button("file radar.") {
            let url = URL(string: "https://github.com/blinksh/blink/wiki/Known-Issue:Cmd-key-stuck-while-switching-between-apps-with-Cmd-Tab")!
            blink_openurl(url)
          }
        }.padding()
      }
  }
}


struct StuckView_Previews: PreviewProvider {
    static var previews: some View {
      StuckView(keyCode: .commandLeft) {
        
      }
    }
}
