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

struct SwiftUISnippetsView: View {
  @ObservedObject var model: SearchModel
  
  @State var transitionFrame: CGRect? = nil
  
  var body: some View {
    HStack(alignment: .top) {
      if model.editingSnippet == nil && model.newSnippetPresented == false {
        Spacer()
        VStack {
          Spacer().onAppear {
            withAnimation(.easeOut(duration: 0.33)) {
              transitionFrame = nil
            }
          }
          
          SnippetsListView(model: model)
            .frame(maxWidth: transitionFrame == nil ? 560 : nil)
            .frame(minWidth: transitionFrame?.width, maxWidth: transitionFrame?.width, minHeight: transitionFrame?.height, maxHeight: transitionFrame?.height)
            .background(
              .regularMaterial,
              in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        
        Spacer()
      }
    }
    .padding([.leading, .trailing, .top], 5) // to match quick actions
    .padding(.bottom, 20)
    .ignoresSafeArea(.all)
  }
}

class SnippetsViewController: UIHostingController<SwiftUISnippetsView>, UIGestureRecognizerDelegate{
  var model: SearchModel!
  var tapGestureRecogninzer: UITapGestureRecognizer!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .clear
  }
  
  public static func create(context: (any SnippetContext)?, transitionFrame: CGRect?) throws -> SnippetsViewController {
    let model = try SearchModel()
    model.snippetContext = context
    let rootView = SwiftUISnippetsView(model: model, transitionFrame: transitionFrame)
    let ctrl = SnippetsViewController(rootView: rootView)
    ctrl.model = model
    model.rootCtrl = ctrl
    let tapRecognizer = UITapGestureRecognizer(target: ctrl, action: #selector(_onTap(_:)))
    ctrl.view.addGestureRecognizer(tapRecognizer)
    ctrl.tapGestureRecogninzer = tapRecognizer
    tapRecognizer.delegate = ctrl
    return ctrl
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.model.inputView?.becomeFirstResponder()
  }
  
  @objc func _onTap(_ recognizer: UITapGestureRecognizer) {
    if model.editingSnippet == nil && model.newSnippetPresented == false {
      model.close()
    }
  }
  
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    touch.view == self.view
  }

}

