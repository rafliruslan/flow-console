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
import SwiftUI
import FlowConsoleSnippets

public struct SnippetView: View {
  var fuzzyMode: Bool
  var index: AttributedString
  var content: AttributedString
  var selected: Bool
  var snippet: Snippet
  @ObservedObject var model: SearchModel
  
  public var body: some View {
    Button {
      self.model.onSnippetTap(snippet)
    } label: {
      VStack(alignment: .leading) {
        HStack {
          Text(index).font(Font(BlinkSnippetsFonts.snippetEditContent)).bold(fuzzyMode)
            .frame(maxWidth: .infinity, alignment: .leading).opacity(fuzzyMode ? 1.0 : 0.4)
          if selected {
            Spacer()
            Text(Image(systemName: "return")).opacity(0.5)
          }
        }
        Text(content).font(Font(BlinkSnippetsFonts.snippetEditContent))
          .frame(maxWidth: .infinity, alignment: .leading)
          .opacity(fuzzyMode ? 0.4 : 1.0)
      }
      .textSelection(.enabled)
      .padding(.all, 6)
      .padding(.leading, 12)
      .background(
        selected ? .ultraThickMaterial : .ultraThinMaterial,
        in: ContainerRelativeShape()
      )
      .overlay(alignment: .leading) {
        if selected {
          ContainerRelativeShape()
            .stroke(lineWidth: 2).foregroundColor(Color(uiColor: UIColor.blinkTint))
        }
      }
    }.buttonStyle(SnippetButtonStyle())
  }
}


struct SnippetButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.5 : 1)
  }
}
