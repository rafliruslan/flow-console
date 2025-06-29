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

public enum BlinkSnippetsFonts {
  //  static let snippetIndex = Font.custom(FLOW_CONSOLE_APP_FONT_NAME, size: 18, relativeTo: .body)
  //  static let snippetContent = Font.custom(FLOW_CONSOLE_APP_FONT_NAME, size: 18, relativeTo: .body)
  static let snippetEditContent = UIFont(name: "JetBrains Mono", size: 18)!
}

public struct SnippetsListView: View {
  @ObservedObject var model: SearchModel
  
  @ViewBuilder
  func snippetView(for snippet: Snippet, selected: Bool) -> some View {
    let fuzzyMode = model.isFuzzyMode
    let index = model.fuzzyResults.matchesMap[snippet]!
    let content = model.searchResults.contentMap[snippet] ?? model.fuzzyResults.contentMap[snippet]!
    SnippetView(
      fuzzyMode: fuzzyMode, index: index, content: content, selected: selected, snippet: snippet, model: model
    ).id(snippet.id)
  }
  
  @ViewBuilder
  public var body: some View {
    VStack {
      let displayResults = model.displayResults
      if displayResults.isEmpty {
        
      } else {
        let selectedIndex = self.model.selectedSnippetIdx!
        ViewThatFits(in: .vertical) {
          VStack() {
            ForEach(displayResults) { snippet in
              let selected = displayResults[selectedIndex] == snippet
              snippetView(for: snippet, selected: selected)
                .scaleEffect(CGSize(width: 1.0, height: -1.0), anchor: .center)
            }
          }
          .scaleEffect(CGSize(width: 1.0, height: -1.0), anchor: .center)
          .padding([.top], 6)
          ScrollViewReader { value in
            ScrollView {
              ForEach(displayResults) { snippet in
                let selected = displayResults[selectedIndex] == snippet
                snippetView(for: snippet, selected: selected)
                  .rotationEffect(Angle(degrees: 180))
                  .scaleEffect(CGSize(width: -1.0, height: 1), anchor: .center)
              }
            }
            .onChange(of: self.model.selectedSnippetIdx) { newValue in
              if let snippet = self.model.currentSelection {
                withAnimation {
                  value.scrollTo(snippet.id, anchor: .bottom)
                }
              }
            }
            // Rotate and mirror to put scrollbar in correct place
            .rotationEffect(Angle(degrees: 180))
            .scaleEffect(CGSize(width: -1.0, height: 1), anchor: .center)
          }
        }
        if model.isFuzzyMode {
          Text("Type \(Image(systemName: "space")) to search the content").font(.footnote).foregroundStyle(Color.secondary)
        }
      }
      HStack {
        SearchView(model: model)
          .frame(maxHeight:44)
          .padding([.bottom], 3)
          .onAppear {
            model.focusOnInput()
          }
        if model.displayResults.isEmpty && !model.fuzzyResults.query.isEmpty {
          CreateOrRefreshTipView(model: model).padding([.leading, .trailing])
        }
      }
    }
    .padding([.leading, .trailing], 6)
  }
}

struct CreateOrRefreshTipView : View {
  @ObservedObject var model: SearchModel
  @State private var showErrorsPopover = false
  @Environment(\.horizontalSizeClass) var sizeClass

  public var body: some View {
    HStack {
      if case .started = model.indexProgress {
        ProgressView()
      } else {
        if sizeClass == .compact {
          Button("\(Image(systemName: "square.and.pencil"))") { model.openNewSnippet() }
            .padding(.trailing)
          Button("\(Image(systemName: "arrow.clockwise"))") { model.refreshIndex() }
        } else {
          Button("Create") { model.openNewSnippet() }
          Text(Image(systemName: "return")).opacity(0.5)
          Text("or").opacity(0.5)
          Button("Refresh") { model.refreshIndex() }
        }
        if case .completed(let errors) = model.indexProgress {
          if let errors = errors {
            Button(action: {
              showErrorsPopover = true
            }) {
              Image(systemName: "circle.fill")
            }
            .tint(.red.opacity(0.9))
            .popover(isPresented: $showErrorsPopover) {
              List {
                ForEach(errors) { error in
                  VStack {
                    Text(error.id).monospaced().bold().font(.caption).padding(.bottom)
                    Text(error.localizedDescription).font(.caption2)
                  }
                }
              }
              .tabViewStyle(.page(indexDisplayMode: .always))
              .frame(minWidth: 200, minHeight: 150, maxHeight: 250)
            }
          }
        }
      }
    }
  }
}
