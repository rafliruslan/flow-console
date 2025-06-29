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

extension BKMoshPrediction: Hashable {
  var label: String {
    switch self {
    case BKMoshPredictionAdaptive: return "Adaptive"
    case BKMoshPredictionAlways: return "Always"
    case BKMoshPredictionNever: return "Never"
    case BKMoshPredictionExperimental: return "Experimental"
    case _: return ""
    }
  }
  
  var hint: String {
    switch self {
    case BKMoshPredictionAdaptive: return "Local echo for slower links [default]"
    case BKMoshPredictionAlways: return "Use local echo even on fast links"
    case BKMoshPredictionNever: return "Never use local echo"
    case BKMoshPredictionExperimental: return "Aggressively echo even when incorrect"
    case _: return ""
    }
  }

  static var all: [BKMoshPrediction] {
    [
      BKMoshPredictionAdaptive,
      BKMoshPredictionAlways,
      BKMoshPredictionNever,
      BKMoshPredictionExperimental
    ]
  }
}

extension BKMoshExperimentalIP: Hashable {
  var label: String {
    switch self {
    case BKMoshExperimentalIPNone: return "None"
    case BKMoshExperimentalIPLocal: return "Local"
    case BKMoshExperimentalIPRemote: return "Remote"
    case _: return ""
    }
  }
  
  var hint: String {
    switch self {
    case BKMoshExperimentalIPNone: return "No experimental IP resolution"
    case BKMoshExperimentalIPLocal: return "Resolve the IP locally"
    case BKMoshExperimentalIPRemote: return "Resolve the IP in the remote"
    case _: return ""
    }
  }

  static var all: [BKMoshExperimentalIP] {
    [
      BKMoshExperimentalIPNone,
      BKMoshExperimentalIPLocal,
      BKMoshExperimentalIPRemote,
    ]
  }
}

struct MoshCustomOptionsPickerView: View {
  @Binding var predictionValue: BKMoshPrediction
  @Binding var overwriteValue: Bool
  @Binding var experimentalIPValue: BKMoshExperimentalIP
  
  var body: some View {
    List {
      Section(footer: Text(predictionValue.hint)) {
        ForEach(BKMoshPrediction.all, id: \.self) { value in
          HStack {
            Text(value.label).tag(value)
            Spacer()
            Checkmark(checked: predictionValue == value)
          }
          .contentShape(Rectangle())
          .onTapGesture { predictionValue = value }
        }
      }
      Section(footer: Text("Prediction overwrites instead of inserting")) {
        HStack {
          Toggle("Overwrite", isOn: $overwriteValue)
        }
      }
      Section(footer: Text(experimentalIPValue.hint)) {
        ForEach(BKMoshExperimentalIP.all, id: \.self) { value in
          HStack {
            Text(value.label).tag(value)
            Spacer()
            Checkmark(checked: experimentalIPValue == value)
          }
          .contentShape(Rectangle())
          .onTapGesture { experimentalIPValue = value }
        }
      }
    }
    .listStyle(InsetGroupedListStyle())
    .navigationTitle("Mosh Options")
  }
}
